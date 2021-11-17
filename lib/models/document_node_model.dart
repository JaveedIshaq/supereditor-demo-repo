// ignore_for_file: unnecessary_this, prefer_collection_literals

class DocumentNodeModel {
  String insert;
  Attributes attributes;

  DocumentNodeModel({this.insert, this.attributes});

  DocumentNodeModel.fromJson(Map<String, dynamic> json) {
    insert = json['insert'] as String;
    attributes = json['attributes'] != null
        ? Attributes.fromJson(json['attributes'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['insert'] = this.insert;
    if (this.attributes != null) {
      data['attributes'] = this.attributes.toJson();
    }
    return data;
  }
}

class Attributes {
  String heading;

  Attributes({this.heading});

  Attributes.fromJson(Map<String, dynamic> json) {
    heading = json['heading'] as String;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['heading'] = this.heading;
    return data;
  }
}
