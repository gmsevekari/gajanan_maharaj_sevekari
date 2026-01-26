import 'dart:convert';
import 'package:flutter/services.dart';

abstract class ContentContainer {
  String get titleKey;
  String get textResourceDirectory;
  String get imageResourceDirectory;
  List<ContentItem> get files;
}

class AppConfig {
  final List<DeityConfig> deities;
  final FavoritesConfig favorites;

  AppConfig({required this.deities, required this.favorites});

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    var list = json['deities'] as List? ?? [];
    List<DeityConfig> deitiesList = list.map((i) => DeityConfig.fromJson(i)).toList();
    return AppConfig(
      deities: deitiesList,
      favorites: FavoritesConfig.fromJson(json['favorites'] ?? {}),
    );
  }
}

class FavoritesConfig {
  final List<String> order;
  final NityopasanaContent sundayPrarthana;
  final NityopasanaContent otherAartis;

  FavoritesConfig({required this.order, required this.sundayPrarthana, required this.otherAartis});

  factory FavoritesConfig.fromJson(Map<String, dynamic> json) {
    return FavoritesConfig(
      order: List<String>.from(json['order'] ?? []),
      sundayPrarthana: NityopasanaContent.fromJson(json['sunday_prarthana'] ?? {}),
      otherAartis: NityopasanaContent.fromJson(json['other_aartis'] ?? {}),
    );
  }

  static Future<FavoritesConfig> fromFile(String path) async {
    final String response = await rootBundle.loadString(path);
    final data = await json.decode(response);
    return FavoritesConfig.fromJson(data);
  }
}

class DeityConfig {
  final String id;
  final String nameEn;
  final String nameMr;
  final String imagePath;
  final String configFile;
  final String aboutFile;
  final NityopasanaConfig nityopasana;
  final DonationInfo donationInfo;
  final List<SocialMediaLink> socialMediaLinks;
  final List<SignupLink> signupLinks;

  DeityConfig({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.imagePath,
    required this.configFile,
    required this.aboutFile,
    required this.nityopasana,
    required this.donationInfo,
    required this.socialMediaLinks,
    required this.signupLinks,
  });

  factory DeityConfig.fromJson(Map<String, dynamic> json) {
    var socialMediaList = json['social_media_links'] as List? ?? [];
    List<SocialMediaLink> socialMediaLinksList = socialMediaList.map((i) => SocialMediaLink.fromJson(i)).toList();

    var signupList = json['signup_links'] as List? ?? [];
    List<SignupLink> signupLinksList = signupList.map((i) => SignupLink.fromJson(i)).toList();

    return DeityConfig(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameMr: json['name_mr'] ?? '',
      imagePath: json['imagePath'] ?? '',
      configFile: json['configFile'] ?? '',
      aboutFile: json['about_file'] ?? '',
      nityopasana: NityopasanaConfig.fromJson(json['nityopasana'] ?? {}),
      donationInfo: DonationInfo.fromJson(json['donation_info'] ?? {}),
      socialMediaLinks: socialMediaLinksList,
      signupLinks: signupLinksList,
    );
  }
}

class AboutDeity {
  final String titleEn;
  final String titleMr;
  final String locationEn;
  final String locationMr;
  final String pragatDinEn;
  final String pragatDinMr;
  final String chantEn;
  final String chantMr;
  final List<AboutSection> sections;
  final String footerQuoteEn;
  final String footerQuoteMr;

  AboutDeity({
    required this.titleEn,
    required this.titleMr,
    required this.locationEn,
    required this.locationMr,
    required this.pragatDinEn,
    required this.pragatDinMr,
    required this.chantEn,
    required this.chantMr,
    required this.sections,
    required this.footerQuoteEn,
    required this.footerQuoteMr,
  });

  factory AboutDeity.fromJson(Map<String, dynamic> json) {
    var list = json['sections'] as List? ?? [];
    List<AboutSection> sectionsList = list.map((i) => AboutSection.fromJson(i)).toList();
    return AboutDeity(
      titleEn: json['title_en'] ?? '',
      titleMr: json['title_mr'] ?? '',
      locationEn: json['location_en'] ?? '',
      locationMr: json['location_mr'] ?? '',
      pragatDinEn: json['pragat_din_en'] ?? '',
      pragatDinMr: json['pragat_din_mr'] ?? '',
      chantEn: json['chant_en'] ?? '',
      chantMr: json['chant_mr'] ?? '',
      sections: sectionsList,
      footerQuoteEn: json['footer_quote_en'] ?? '',
      footerQuoteMr: json['footer_quote_mr'] ?? '',
    );
  }

  static Future<AboutDeity> fromFile(String path) async {
    final String response = await rootBundle.loadString(path);
    final data = await json.decode(response);
    return AboutDeity.fromJson(data);
  }
}

class AboutSection {
  final String titleEn;
  final String titleMr;
  final String contentEn;
  final String contentMr;

  AboutSection({
    required this.titleEn,
    required this.titleMr,
    required this.contentEn,
    required this.contentMr,
  });

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    return AboutSection(
      titleEn: json['title_en'] ?? '',
      titleMr: json['title_mr'] ?? '',
      contentEn: json['content_en'] ?? '',
      contentMr: json['content_mr'] ?? '',
    );
  }
}

class NityopasanaConfig {
  final List<String> order;
  final NityopasanaContent granth;
  final NityopasanaContent bhajans;
  final NityopasanaContent stotras;
  final AartiContent aartis;
  final NamavaliContent namavali;

  NityopasanaConfig({
    required this.order,
    required this.granth,
    required this.bhajans,
    required this.stotras,
    required this.aartis,
    required this.namavali,
  });

  factory NityopasanaConfig.fromJson(Map<String, dynamic> json) {
    return NityopasanaConfig(
      order: List<String>.from(json['order'] ?? []),
      granth: NityopasanaContent.fromJson(json['granth'] ?? {}),
      bhajans: NityopasanaContent.fromJson(json['bhajans'] ?? {}),
      stotras: NityopasanaContent.fromJson(json['stotras'] ?? {}),
      aartis: AartiContent.fromJson(json['aartis'] ?? {}),
      namavali: NamavaliContent.fromJson(json['namavali'] ?? {}),
    );
  }
}

class NityopasanaContent implements ContentContainer {
  @override
  final String titleKey;
  final String icon;
  @override
  final String textResourceDirectory;
  @override
  final String imageResourceDirectory;
  @override
  final List<ContentItem> files;

  NityopasanaContent({required this.titleKey, required this.icon, required this.textResourceDirectory, required this.imageResourceDirectory, required this.files});

  factory NityopasanaContent.fromJson(Map<String, dynamic> json) {
    var fileList = json['files'] as List? ?? [];
    List<ContentItem> contentItems = fileList.map((i) => ContentItem.fromJson(i)).toList();
    return NityopasanaContent(
      titleKey: json['title_key'] ?? '',
      icon: json['icon'] ?? '',
      textResourceDirectory: json['textResourceDirectory'] ?? '',
      imageResourceDirectory: json['imageResourceDirectory'] ?? '',
      files: contentItems,
    );
  }
}

class ContentItem {
  final String file;
  final String image;
  final String? textResourceDirectory;
  final String? imageResourceDirectory;

  ContentItem({required this.file, required this.image, this.textResourceDirectory, this.imageResourceDirectory});

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      file: json['file'] ?? '',
      image: json['image'] ?? '',
      textResourceDirectory: json['textResourceDirectory'],
      imageResourceDirectory: json['imageResourceDirectory'],
    );
  }
}

class AartiContent {
  final String titleKey;
  final String icon;
  final List<AartiCategoryConfig> categories;

  AartiContent({required this.titleKey, required this.icon, required this.categories});

  factory AartiContent.fromJson(Map<String, dynamic> json) {
    var categoryList = json['categories'] as List? ?? [];
    List<AartiCategoryConfig> categoryConfigList =
        categoryList.map((i) => AartiCategoryConfig.fromJson(i)).toList();
    return AartiContent(
      titleKey: json['title_key'] ?? '',
      icon: json['icon'] ?? '',
      categories: categoryConfigList,
    );
  }
}

class AartiCategoryConfig implements ContentContainer {
  final String id;
  @override
  final String titleKey;
  @override
  final String textResourceDirectory;
  @override
  final String imageResourceDirectory;
  @override
  final List<ContentItem> files;

  AartiCategoryConfig({required this.id, required this.titleKey, required this.textResourceDirectory, required this.imageResourceDirectory, required this.files});

  factory AartiCategoryConfig.fromJson(Map<String, dynamic> json) {
    var fileList = json['files'] as List? ?? [];
    List<ContentItem> contentItems = fileList.map((i) => ContentItem.fromJson(i)).toList();
    return AartiCategoryConfig(
      id: json['id'] ?? '',
      titleKey: json['title_key'] ?? '',
      textResourceDirectory: json['textResourceDirectory'] ?? '',
      imageResourceDirectory: json['imageResourceDirectory'] ?? '',
      files: contentItems,
    );
  }
}

class NamavaliContent {
  final String titleKey;
  final String icon;
  final String file;
  final String image;
  final String textResourceDirectory;
  final String imageResourceDirectory;

  NamavaliContent({required this.titleKey, required this.icon, required this.file, required this.image, required this.textResourceDirectory, required this.imageResourceDirectory});

  factory NamavaliContent.fromJson(Map<String, dynamic> json) {
    return NamavaliContent(
      titleKey: json['title_key'] ?? '',
      icon: json['icon'] ?? '',
      file: json['file'] ?? '',
      image: json['image'] ?? '',
      textResourceDirectory: json['textResourceDirectory'] ?? '',
      imageResourceDirectory: json['imageResourceDirectory'] ?? '',
    );
  }
}

class DonationInfo {
  final String qrCodeLight;
  final String qrCodeDark;
  final String zelleUrl;

  DonationInfo({
    required this.qrCodeLight,
    required this.qrCodeDark,
    required this.zelleUrl,
  });

  factory DonationInfo.fromJson(Map<String, dynamic> json) {
    return DonationInfo(
      qrCodeLight: json['qr_code_light'] ?? '',
      qrCodeDark: json['qr_code_dark'] ?? '',
      zelleUrl: json['zelle_url'] ?? '',
    );
  }
}

class SocialMediaLink {
  final String platform;
  final String icon;
  final String url;
  final String color;

  SocialMediaLink({required this.platform, required this.icon, required this.url, required this.color});

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) {
    return SocialMediaLink(
      platform: json['platform'] ?? '',
      icon: json['icon'] ?? '',
      url: json['url'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class SignupLink {
  final String platformKey;
  final String descriptionKey;
  final String icon;
  final String url;
  final String color;

  SignupLink({
    required this.platformKey,
    required this.descriptionKey,
    required this.icon,
    required this.url,
    required this.color,
  });

  factory SignupLink.fromJson(Map<String, dynamic> json) {
    return SignupLink(
      platformKey: json['platform_key'] ?? '',
      descriptionKey: json['description_key'] ?? '',
      icon: json['icon'] ?? '',
      url: json['url'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
