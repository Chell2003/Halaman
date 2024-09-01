class Pot {
  String name;
  String type;
  String channelId;
  String apiKey;
  String ipAddress;

  Pot({required this.name, required this.type, required this.channelId, required this.apiKey, required this.ipAddress});

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'channelId': channelId,
    'apiKey': apiKey,
    'ipAddress': ipAddress,
  };

  factory Pot.fromJson(Map<String, dynamic> json) => Pot(
    name: json['name'],
    type: json['type'],
    channelId: json['channelId'],
    apiKey: json['apiKey'],
    ipAddress: json['ipAddress'],
  );
}
