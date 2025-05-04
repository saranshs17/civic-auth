class Wallet {
  final String? address;
  final String? blockchain;

  Wallet({
    this.address,
    this.blockchain,
  });

  factory Wallet.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Wallet();
    }
    return Wallet(
      address: json['address'] as String?,
      blockchain: json['blockchain'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'blockchain': blockchain,
    };
  }

  String get shortAddress {
    if (address == null || address!.isEmpty) return 'N/A';
    if (address!.length <= 10) return address!;
    return '${address!.substring(0, 6)}...${address!.substring(address!.length - 4)}';
  }
}