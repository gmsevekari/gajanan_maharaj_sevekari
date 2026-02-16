import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr'),
  ];

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @granthTitle.
  ///
  /// In en, this message translates to:
  /// **'Gajanan Vijay Granth'**
  String get granthTitle;

  /// No description provided for @stotraTitle.
  ///
  /// In en, this message translates to:
  /// **'Stotra Collection'**
  String get stotraTitle;

  /// No description provided for @namavaliTitle.
  ///
  /// In en, this message translates to:
  /// **'108 Namavali'**
  String get namavaliTitle;

  /// No description provided for @aartiTitle.
  ///
  /// In en, this message translates to:
  /// **'Aarti Collection'**
  String get aartiTitle;

  /// No description provided for @bhajanTitle.
  ///
  /// In en, this message translates to:
  /// **'Bhajan Collection'**
  String get bhajanTitle;

  /// No description provided for @sankalpTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Abhishek and Pooja Sankalp'**
  String get sankalpTitle;

  /// No description provided for @parayanTitle.
  ///
  /// In en, this message translates to:
  /// **'Parayan Organization'**
  String get parayanTitle;

  /// No description provided for @aboutMaharajTitle.
  ///
  /// In en, this message translates to:
  /// **'About Maharaj'**
  String get aboutMaharajTitle;

  /// No description provided for @aboutBabaTitle.
  ///
  /// In en, this message translates to:
  /// **'About Baba'**
  String get aboutBabaTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Calendar'**
  String get calendarTitle;

  /// No description provided for @donationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donationsTitle;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gajanan Maharaj Sevekari'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @adhyay.
  ///
  /// In en, this message translates to:
  /// **'Adhyay'**
  String get adhyay;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @stotraAvahan.
  ///
  /// In en, this message translates to:
  /// **'Gajanan Maharaj Avahan'**
  String get stotraAvahan;

  /// No description provided for @stotraBavanni.
  ///
  /// In en, this message translates to:
  /// **'Gajanan Maharaj Bavanni'**
  String get stotraBavanni;

  /// No description provided for @dailyAartis.
  ///
  /// In en, this message translates to:
  /// **'Daily Aartis'**
  String get dailyAartis;

  /// No description provided for @eventAartis.
  ///
  /// In en, this message translates to:
  /// **'Event Aartis'**
  String get eventAartis;

  /// No description provided for @otherAartis.
  ///
  /// In en, this message translates to:
  /// **'Other Aartis'**
  String get otherAartis;

  /// No description provided for @otherStotras.
  ///
  /// In en, this message translates to:
  /// **'Other Stotras'**
  String get otherStotras;

  /// No description provided for @ganapatiAarti.
  ///
  /// In en, this message translates to:
  /// **'Ganapati Aarti'**
  String get ganapatiAarti;

  /// No description provided for @deviAarti.
  ///
  /// In en, this message translates to:
  /// **'Devi Aarti'**
  String get deviAarti;

  /// No description provided for @dattaMaharajAarti.
  ///
  /// In en, this message translates to:
  /// **'Datta Maharaj Aarti'**
  String get dattaMaharajAarti;

  /// No description provided for @shankarAarti.
  ///
  /// In en, this message translates to:
  /// **'Shankar Aarti'**
  String get shankarAarti;

  /// No description provided for @vitthalAarti.
  ///
  /// In en, this message translates to:
  /// **'Vitthal Aarti'**
  String get vitthalAarti;

  /// No description provided for @khandobaAarti.
  ///
  /// In en, this message translates to:
  /// **'Khandoba Aarti'**
  String get khandobaAarti;

  /// No description provided for @saiBabaAarti.
  ///
  /// In en, this message translates to:
  /// **'Sai Baba Aarti'**
  String get saiBabaAarti;

  /// No description provided for @dnyaneshwarMaharajAarti.
  ///
  /// In en, this message translates to:
  /// **'Dnyaneshwar Maharaj Aarti'**
  String get dnyaneshwarMaharajAarti;

  /// No description provided for @tukaramMaharajAarti.
  ///
  /// In en, this message translates to:
  /// **'Tukaram Maharaj Aarti'**
  String get tukaramMaharajAarti;

  /// No description provided for @karpurAarti.
  ///
  /// In en, this message translates to:
  /// **'Karpur Aarti'**
  String get karpurAarti;

  /// No description provided for @prarthana.
  ///
  /// In en, this message translates to:
  /// **'Prarthana'**
  String get prarthana;

  /// No description provided for @mantrapushpanjali.
  ///
  /// In en, this message translates to:
  /// **'Mantrapushpanjali'**
  String get mantrapushpanjali;

  /// No description provided for @kakadAarti.
  ///
  /// In en, this message translates to:
  /// **'Kakad Aarti'**
  String get kakadAarti;

  /// No description provided for @madhyanAarti.
  ///
  /// In en, this message translates to:
  /// **'Madhyan Aarti'**
  String get madhyanAarti;

  /// No description provided for @dhoopAarti.
  ///
  /// In en, this message translates to:
  /// **'Dhoop Aarti'**
  String get dhoopAarti;

  /// No description provided for @shejAarti.
  ///
  /// In en, this message translates to:
  /// **'Shej Aarti'**
  String get shejAarti;

  /// No description provided for @prakatDinAarti.
  ///
  /// In en, this message translates to:
  /// **'Prakat Din Aarti'**
  String get prakatDinAarti;

  /// No description provided for @ashadhiEkadashiAarti.
  ///
  /// In en, this message translates to:
  /// **'Ashadhi Ekadashi Aarti'**
  String get ashadhiEkadashiAarti;

  /// No description provided for @dattaJayantiAarti.
  ///
  /// In en, this message translates to:
  /// **'Datta Jayanti Aarti'**
  String get dattaJayantiAarti;

  /// No description provided for @ramNavamiAarti.
  ///
  /// In en, this message translates to:
  /// **'Ram Navami Aarti'**
  String get ramNavamiAarti;

  /// No description provided for @akshayTritiyaAarti.
  ///
  /// In en, this message translates to:
  /// **'Akshay Tritiya Aarti'**
  String get akshayTritiyaAarti;

  /// No description provided for @rushiPanchamiAarti.
  ///
  /// In en, this message translates to:
  /// **'Rushi Panchami Aarti'**
  String get rushiPanchamiAarti;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @bhajanGajananachya.
  ///
  /// In en, this message translates to:
  /// **'Gajananachya Charani Julavu'**
  String get bhajanGajananachya;

  /// No description provided for @bhajanMurtiAhe.
  ///
  /// In en, this message translates to:
  /// **'Murti Ahe Shegaonla'**
  String get bhajanMurtiAhe;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @generateSankalp.
  ///
  /// In en, this message translates to:
  /// **'Generate Sankalp'**
  String get generateSankalp;

  /// No description provided for @sankalpGenerated.
  ///
  /// In en, this message translates to:
  /// **'Sankalp for {location} on {date} will be generated here based on the Sampurna Chaturmas book.'**
  String sankalpGenerated(String location, String date);

  /// No description provided for @chooseParayanType.
  ///
  /// In en, this message translates to:
  /// **'Choose Parayan Type:'**
  String get chooseParayanType;

  /// No description provided for @oneDayParayan.
  ///
  /// In en, this message translates to:
  /// **'1-Day Parayan'**
  String get oneDayParayan;

  /// No description provided for @threeDayParayan.
  ///
  /// In en, this message translates to:
  /// **'3-Day Parayan'**
  String get threeDayParayan;

  /// No description provided for @oneDayParayanProgress.
  ///
  /// In en, this message translates to:
  /// **'1-Day Parayan Progress'**
  String get oneDayParayanProgress;

  /// No description provided for @threeDayParayanProgress.
  ///
  /// In en, this message translates to:
  /// **'3-Day Parayan Progress'**
  String get threeDayParayanProgress;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @donationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please scan the QR code or click the button below to donate. Jai Gajanan 🙏🏻'**
  String get donationInstruction;

  /// No description provided for @donateViaZelle.
  ///
  /// In en, this message translates to:
  /// **'Donate via Zelle to gajananmaharajseattle@gmail.com'**
  String get donateViaZelle;

  /// No description provided for @zelleQRCode.
  ///
  /// In en, this message translates to:
  /// **'Zelle QR Code Placeholder'**
  String get zelleQRCode;

  /// No description provided for @qrCodeHere.
  ///
  /// In en, this message translates to:
  /// **'QR Code Here'**
  String get qrCodeHere;

  /// No description provided for @couldNotOpenZelle.
  ///
  /// In en, this message translates to:
  /// **'Could not open Zelle.'**
  String get couldNotOpenZelle;

  /// No description provided for @eventOnDate.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get eventOnDate;

  /// No description provided for @aboutMaharajContent.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive information and history about Gajanan Maharaj will be displayed here. The content is presented in large, legible Marathi text, designed for easy reading by elderly users.'**
  String get aboutMaharajContent;

  /// No description provided for @upcomingEvent.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Event'**
  String get upcomingEvent;

  /// No description provided for @prakatDinUtsav.
  ///
  /// In en, this message translates to:
  /// **'Prakat Din Utsav'**
  String get prakatDinUtsav;

  /// No description provided for @aboutMaharajScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Shri Sant Gajanan Maharaj'**
  String get aboutMaharajScreenTitle;

  /// No description provided for @aboutMaharajLocation.
  ///
  /// In en, this message translates to:
  /// **'Shegaon, Maharashtra'**
  String get aboutMaharajLocation;

  /// No description provided for @aboutMaharajPragatDin.
  ///
  /// In en, this message translates to:
  /// **'Pragat Din: February 23, 1878 (Magh Vadya Saptami)'**
  String get aboutMaharajPragatDin;

  /// No description provided for @aboutMaharajChant.
  ///
  /// In en, this message translates to:
  /// **'|| Gan Gan Ganat Bote ||'**
  String get aboutMaharajChant;

  /// No description provided for @cardTitleJeevanParichay.
  ///
  /// In en, this message translates to:
  /// **'Introduction to Life'**
  String get cardTitleJeevanParichay;

  /// No description provided for @cardContentJeevanParichay.
  ///
  /// In en, this message translates to:
  /// **'Sant Shree Gajanan Maharaj is one of Maharashtra’s most revered saints, known for his simplicity, divine presence, and miraculous acts. Through His incarnation, He illuminated the paths of numerous lives in His short but divine life of 32 years.\n\nThough His origins, birth, and lineage remain unknown, His impact is eternal. For 32 years, He graced the holy land of Shegaon, transforming it into a spiritual sanctuary. He was a \"Yogiraj\" in the truest sense, guiding countless souls through His miraculous Leelas (divine plays) and His mere presence, which radiated peace and absolute divinity.'**
  String get cardContentJeevanParichay;

  /// No description provided for @cardTitlePragatItihas.
  ///
  /// In en, this message translates to:
  /// **'History of Appearance'**
  String get cardTitlePragatItihas;

  /// No description provided for @cardContentPragatItihas.
  ///
  /// In en, this message translates to:
  /// **'Maharaj first appeared in Shegaon (in the Buldhana district of Maharashtra) on February 23, 1878 (Magh Vadya Saptami).\n\nMaharaj was seen as a young man with a radiant aura, sitting in the street and picking rice grains from discarded patravali (leaf plates) to eat. This act conveyed his first profound teaching: Annam Brahmeti (\"Food is Brahma/God\") — food should never be wasted and that for a realized soul, all matter is one. From the moment of his appearance, devotees recognized him as a spiritually awakened soul - “Yogiraj” and “Ansuya putra” (a child of divine detachment).'**
  String get cardContentPragatItihas;

  /// No description provided for @cardTitleShikvan.
  ///
  /// In en, this message translates to:
  /// **'Teachings and Philosophy'**
  String get cardTitleShikvan;

  /// No description provided for @cardContentShikvan.
  ///
  /// In en, this message translates to:
  /// **'Maharaj is often associated with the Avadhut Sampradaya, characterized by saints who transcend material norms, express innocence and divine madness, and live in constant union with the Supreme.\n\nHis core philosophy is encapsulated in his constant chant: \"Gan Gan Ganat Bote.\" This mantra signifies that the individual soul (Jiva) is woven into the Universal Soul (Brahma), and God is present in every atom of existence.\n\nKey Pillars of His Teachings:\n* Annam Brahma: Respect for food as a divine entity.\n* Equality: He treated rich and poor, humans and animals, with equal love, rejecting caste and creed.\n* Karma Yoga: He emphasized doing one\'s duty without attachment to the fruit of actions.\n* Values: He guided devotees to follow the path of Bhakti (Devotion), Seva (Selfless Service), Sadachaar (Moral Conduct), and Tyag (Detachment).'**
  String get cardContentShikvan;

  /// No description provided for @cardTitleSamadhi.
  ///
  /// In en, this message translates to:
  /// **'Samadhi Details'**
  String get cardTitleSamadhi;

  /// No description provided for @cardContentSamadhi.
  ///
  /// In en, this message translates to:
  /// **'He spent 32 years in Shegaon, performing countless miracles (Leelas) to guide devotees toward the path of righteousness before taking Sanjeevan Samadhi — a state where a saint voluntarily exits the body while remaining conscious in the super-conscious state - on September 8, 1910 (Rishi Panchami).\n\nHis physical body rests in the Samadhi Mandir in Shegaon, but His spiritual presence is timeless. Before taking Samadhi, He assured His devotees: \"I am here, though I leave my body. Do not let your devotion waver, I will always be with you to protect you.\"\n\nToday, Shegaon is known as the \"Pandharpur of Vidarbha,\" where millions flock to experience the living presence of the Master.'**
  String get cardContentSamadhi;

  /// No description provided for @footerQuote.
  ///
  /// In en, this message translates to:
  /// **'An ocean of mercy who rushes to the call of devotees'**
  String get footerQuote;

  /// No description provided for @socialMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMediaTitle;

  /// No description provided for @officialSocialMediaHandles.
  ///
  /// In en, this message translates to:
  /// **'The official social media handles'**
  String get officialSocialMediaHandles;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @googlePhotos.
  ///
  /// In en, this message translates to:
  /// **'Google Photos'**
  String get googlePhotos;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @officialPage.
  ///
  /// In en, this message translates to:
  /// **'Official Page'**
  String get officialPage;

  /// No description provided for @videosAndStreams.
  ///
  /// In en, this message translates to:
  /// **'Videos and Live Streams'**
  String get videosAndStreams;

  /// No description provided for @photosAndReels.
  ///
  /// In en, this message translates to:
  /// **'Photos and Reels'**
  String get photosAndReels;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Festival Photo Gallery'**
  String get photoGallery;

  /// No description provided for @whatsappAdminContact.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Group Admin Contact'**
  String get whatsappAdminContact;

  /// No description provided for @officialLinks.
  ///
  /// In en, this message translates to:
  /// **'Official Links'**
  String get officialLinks;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @nityopasanaTitle.
  ///
  /// In en, this message translates to:
  /// **'Nityopasana'**
  String get nityopasanaTitle;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @narrator.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get narrator;

  /// No description provided for @internetRequired.
  ///
  /// In en, this message translates to:
  /// **'Video playback requires internet'**
  String get internetRequired;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this Adhyay from Gajanan Vijay Granth'**
  String get shareMessage;

  /// No description provided for @signupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Signups'**
  String get signupsTitle;

  /// No description provided for @signupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please use the links below to signup for various sevas.'**
  String get signupsDescription;

  /// No description provided for @sundayPrasadSevaSignup.
  ///
  /// In en, this message translates to:
  /// **'Sunday Prasad Seva'**
  String get sundayPrasadSevaSignup;

  /// No description provided for @sundayPrasadSevaSignupDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign up for the Sunday Prasad Cooking Seva'**
  String get sundayPrasadSevaSignupDescription;

  /// No description provided for @vastralankarSevaSignup.
  ///
  /// In en, this message translates to:
  /// **'Vastra-Alankar Seva'**
  String get vastralankarSevaSignup;

  /// No description provided for @vastralankarSevaSignupDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign up for the Vastra-Alankar Seva'**
  String get vastralankarSevaSignupDescription;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @searchEvent.
  ///
  /// In en, this message translates to:
  /// **'Search Event...'**
  String get searchEvent;

  /// No description provided for @allEventsList.
  ///
  /// In en, this message translates to:
  /// **'All Events List'**
  String get allEventsList;

  /// No description provided for @namavaliFooter.
  ///
  /// In en, this message translates to:
  /// **'Shri Gajanan-arpanamastu'**
  String get namavaliFooter;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get favoritesTitle;

  /// No description provided for @sundayPrarthanaTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunday Prarthana'**
  String get sundayPrarthanaTitle;

  /// No description provided for @guruGeeta.
  ///
  /// In en, this message translates to:
  /// **'Guru Geeta'**
  String get guruGeeta;

  /// No description provided for @dattaMajala.
  ///
  /// In en, this message translates to:
  /// **'Datta Majala Prasanna Hoshi'**
  String get dattaMajala;

  /// No description provided for @karunaTripadi.
  ///
  /// In en, this message translates to:
  /// **'Shri Karuna Tripadi'**
  String get karunaTripadi;

  /// No description provided for @gajananBavanni.
  ///
  /// In en, this message translates to:
  /// **'Gajanan Bavanni'**
  String get gajananBavanni;

  /// No description provided for @siddhaMangal.
  ///
  /// In en, this message translates to:
  /// **'Shri Siddhamangal Stotra'**
  String get siddhaMangal;

  /// No description provided for @ghorKashtodharan.
  ///
  /// In en, this message translates to:
  /// **'Shri Ghorakashtodharan Stotra'**
  String get ghorKashtodharan;

  /// No description provided for @dattaStuti.
  ///
  /// In en, this message translates to:
  /// **'Datta Stuti'**
  String get dattaStuti;

  /// No description provided for @namjap.
  ///
  /// In en, this message translates to:
  /// **'Naamjap'**
  String get namjap;

  /// No description provided for @namavaliListenTitle.
  ///
  /// In en, this message translates to:
  /// **'108 Namavali - Ravindra Sathe'**
  String get namavaliListenTitle;

  /// No description provided for @namavaliShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out the Gajanan Maharaj 108 Namavali'**
  String get namavaliShareMessage;

  /// No description provided for @contentShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this content'**
  String get contentShareMessage;

  /// No description provided for @copyrightMessage.
  ///
  /// In en, this message translates to:
  /// **'© {year} Gajanan Maharaj Seattle'**
  String copyrightMessage(String year);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
