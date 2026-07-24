class ListingModel {
  final String id;
  final String name;
  final String type;
  final String donor;
  final String imageUrl;

  ListingModel({
    required this.id,
    required this.name,
    required this.type,
    required this.donor,
    required this.imageUrl,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    String image = 'https://via.placeholder.com/150';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      var firstImg = json['images'][0];
      if (firstImg is Map) {
        image = firstImg['url'] ?? image;
      } else if (firstImg is String) {
        image = firstImg;
      }
    }
    return ListingModel(
      id: json['id']?.toString() ?? '',
      name: json['title'] ?? json['name'] ?? 'Unknown Item',
      type: json['type'] ?? json['category'] ?? 'General',
      donor: json['created_by_name'] ?? 'Local Resident',
      imageUrl: image,
    );
  }
}
