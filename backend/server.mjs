import express from 'express';
import cookieParser from 'cookie-parser';
import bodyParser from 'body-parser';
import cors from 'cors';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';
import { CivicAuth } from '@civic/auth/server';
import session from 'express-session';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;


app.use(cookieParser());
app.use(bodyParser.json());
const whitelist = process.env.ALLOWED_ORIGINS.split(',');
app.use(cors({
  origin: function(origin, callback) {
    // allow requests with no origin (mobile apps, curl)
    if (!origin) return callback(null, true);
    if (whitelist.includes(origin)) {
      return callback(null, true);
    }
    callback(new Error(`Origin ${origin} not allowed by CORS`));
  },
  credentials: true
}));
app.options('*', cors());


// Configure session middleware
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // Set to true if using HTTPS
}));

const config = {
  clientId: process.env.CIVIC_CLIENT_ID,
  redirectUrl: process.env.REDIRECT_URL,
  postLogoutRedirectUrl: process.env.POST_LOGOUT_URL
};

// Middleware to attach CivicAuth with session-based storage
app.use((req, res, next) => {
  const storage = {
    get: function(key) {
      return req.session[key];
    },
    set: function(key, value) {
      req.session[key] = value;
    }
  };
  req.civicAuth = new CivicAuth(storage, config);
  next();
});

// Login route
app.get('/auth/login', async (req, res) => {
  try {
    const url = await req.civicAuth.buildLoginUrl();
    res.json({ loginUrl: url.toString() });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'buildLoginUrl failed' });
  }
});

// Callback route
app.get('/auth/callback', async (req, res) => {
  const { code, state } = req.query;
  await req.civicAuth.resolveOAuthAccessCode(code, state);
  const user = await req.civicAuth.getUser();
  const token = jwt.sign({ user }, process.env.JWT_SECRET, { expiresIn: '1h' });
  res.redirect(`${process.env.FLUTTER_SUCCESS_REDIRECT}?token=${token}`);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});