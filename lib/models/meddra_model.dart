class MedDraModel {
  String? code;
  String? abrev;
  String? text;
  String? parentId;
  List<Nodes>? nodes;

  MedDraModel({this.code, this.abrev, this.text, this.parentId, this.nodes});

  MedDraModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    abrev = json['abrev'];
    text = json['text'];
    parentId = json['parent_id'];
    if (json['nodes'] != null) {
      nodes = <Nodes>[];
      json['nodes'].forEach((v) {
        nodes!.add(Nodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['abrev'] = abrev;
    data['text'] = text;
    data['parent_id'] = parentId;
    if (nodes != null) {
      data['nodes'] = nodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Nodes {
  String? code;
  String? abrev;
  String? text;
  String? parentId;

  Nodes({this.code, this.abrev, this.text, this.parentId});

  Nodes.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    abrev = json['abrev'];
    text = json['text'];
    parentId = json['parent_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['abrev'] = abrev;
    data['text'] = text;
    data['parent_id'] = parentId;
    return data;
  }
}

