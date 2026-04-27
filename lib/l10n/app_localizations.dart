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

  /// No description provided for @guruCharitraTitle.
  ///
  /// In en, this message translates to:
  /// **'Shri Guru Charitra'**
  String get guruCharitraTitle;

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
  /// **'Parayan'**
  String get parayanTitle;

  /// No description provided for @parayanListTitle.
  ///
  /// In en, this message translates to:
  /// **'Parayan List'**
  String get parayanListTitle;

  /// No description provided for @songTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songTitle;

  /// No description provided for @aboutMaharajTitle.
  ///
  /// In en, this message translates to:
  /// **'About Maharaj'**
  String get aboutMaharajTitle;

  /// No description provided for @aboutGanapatiTitle.
  ///
  /// In en, this message translates to:
  /// **'About Ganapati'**
  String get aboutGanapatiTitle;

  /// No description provided for @aboutShriramTitle.
  ///
  /// In en, this message translates to:
  /// **'About Prabhu Shriram'**
  String get aboutShriramTitle;

  /// No description provided for @aboutBabaTitle.
  ///
  /// In en, this message translates to:
  /// **'About Baba'**
  String get aboutBabaTitle;

  /// No description provided for @aboutHanumanTitle.
  ///
  /// In en, this message translates to:
  /// **'About Shri Hanuman'**
  String get aboutHanumanTitle;

  /// No description provided for @aboutDattaMaharajTitle.
  ///
  /// In en, this message translates to:
  /// **'About Shri Datta Maharaj'**
  String get aboutDattaMaharajTitle;

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

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// No description provided for @themeSaffron.
  ///
  /// In en, this message translates to:
  /// **'Saffron'**
  String get themeSaffron;

  /// No description provided for @themeMaroon.
  ///
  /// In en, this message translates to:
  /// **'Maroon'**
  String get themeMaroon;

  /// No description provided for @themeSandalwood.
  ///
  /// In en, this message translates to:
  /// **'Sandalwood'**
  String get themeSandalwood;

  /// No description provided for @themeIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get themeIndigo;

  /// No description provided for @themeTulsi.
  ///
  /// In en, this message translates to:
  /// **'Tulsi Green'**
  String get themeTulsi;

  /// No description provided for @themeKumkum.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get themeKumkum;

  /// No description provided for @themeLotus.
  ///
  /// In en, this message translates to:
  /// **'Lotus Pink'**
  String get themeLotus;

  /// No description provided for @themePeacock.
  ///
  /// In en, this message translates to:
  /// **'Peacock Blue'**
  String get themePeacock;

  /// No description provided for @themeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeCustom;

  /// No description provided for @customColorPicker.
  ///
  /// In en, this message translates to:
  /// **'Pick Your Color'**
  String get customColorPicker;

  /// No description provided for @savedThemes.
  ///
  /// In en, this message translates to:
  /// **'My Themes'**
  String get savedThemes;

  /// No description provided for @saveTheme.
  ///
  /// In en, this message translates to:
  /// **'Save Theme'**
  String get saveTheme;

  /// No description provided for @deleteTheme.
  ///
  /// In en, this message translates to:
  /// **'Delete Theme'**
  String get deleteTheme;

  /// No description provided for @themeSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme added to library'**
  String get themeSaved;

  /// No description provided for @themeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Theme removed'**
  String get themeDeleted;

  /// No description provided for @noSavedThemes.
  ///
  /// In en, this message translates to:
  /// **'No saved themes yet'**
  String get noSavedThemes;

  /// No description provided for @themeAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'Theme already exists in library'**
  String get themeAlreadySaved;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex Code'**
  String get hexLabel;

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

  /// No description provided for @otherBhajans.
  ///
  /// In en, this message translates to:
  /// **'Other Bhajans'**
  String get otherBhajans;

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

  /// No description provided for @findMyAllocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Find My Adhyays'**
  String get findMyAllocationLabel;

  /// No description provided for @findMyAllocationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Use \'Find My Adhyays\' to see your adhyay allocation.'**
  String get findMyAllocationPlaceholder;

  /// No description provided for @claimedLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhyay Claimed'**
  String get claimedLabel;

  /// No description provided for @unclaimedLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhyay Unclaimed'**
  String get unclaimedLabel;

  /// No description provided for @claimSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Adhyay allocation linked successfully!'**
  String get claimSuccessMessage;

  /// No description provided for @alreadyLinkedPrompt.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already linked to another device. Move it to this device?'**
  String get alreadyLinkedPrompt;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get phoneNumberHint;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneError;

  /// No description provided for @claimInProgress.
  ///
  /// In en, this message translates to:
  /// **'Linking allocation...'**
  String get claimInProgress;

  /// No description provided for @noAllocationFound.
  ///
  /// In en, this message translates to:
  /// **'No allocation found for this phone number.'**
  String get noAllocationFound;

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

  /// No description provided for @guruPushyaParayan.
  ///
  /// In en, this message translates to:
  /// **'Guru Pushya Parayan'**
  String get guruPushyaParayan;

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
  /// **'Upcoming Events'**
  String get upcomingEvent;

  /// No description provided for @prakatDinUtsav.
  ///
  /// In en, this message translates to:
  /// **'Prakat Din Utsav'**
  String get prakatDinUtsav;

  /// No description provided for @weeklyPooja.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pooja'**
  String get weeklyPooja;

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

  /// No description provided for @allEvents.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get allEvents;

  /// No description provided for @searchEvent.
  ///
  /// In en, this message translates to:
  /// **'Search Event...'**
  String get searchEvent;

  /// No description provided for @allEventsList.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get allEventsList;

  /// No description provided for @namavaliFooter.
  ///
  /// In en, this message translates to:
  /// **'Shri Gajanan-arpanamastu'**
  String get namavaliFooter;

  /// No description provided for @otherTitle.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherTitle;

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

  /// No description provided for @downloadAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Download the App'**
  String get downloadAppTitle;

  /// No description provided for @downloadAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get our official app for offline use'**
  String get downloadAppSubtitle;

  /// No description provided for @downloadAppButton.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get downloadAppButton;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @weeklyPoojaReminder.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pooja Reminders'**
  String get weeklyPoojaReminder;

  /// No description provided for @notificationsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'To receive notifications, please enable them in your device settings.'**
  String get notificationsDisabledMessage;

  /// No description provided for @notificationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Updated!'**
  String get notificationDialogTitle;

  /// No description provided for @notificationDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive event reminders and important temple announcements.\n\nYou can change your preferences at any time in Settings > Notification Preferences'**
  String get notificationDialogBody;

  /// No description provided for @notificationDialogAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notificationDialogAllow;

  /// No description provided for @notificationDialogDeny.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notificationDialogDeny;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @specialEvents.
  ///
  /// In en, this message translates to:
  /// **'Special Events'**
  String get specialEvents;

  /// No description provided for @gajananChant.
  ///
  /// In en, this message translates to:
  /// **'Gan Gan Ganat Bote'**
  String get gajananChant;

  /// No description provided for @chantGanpatiBappa.
  ///
  /// In en, this message translates to:
  /// **'Ganpati Bappa Moraya'**
  String get chantGanpatiBappa;

  /// No description provided for @chantHappyDiwali.
  ///
  /// In en, this message translates to:
  /// **'Happy Diwali'**
  String get chantHappyDiwali;

  /// No description provided for @chantOmGajananay.
  ///
  /// In en, this message translates to:
  /// **'Om Shri Gajananay Namah'**
  String get chantOmGajananay;

  /// No description provided for @chantShriGajananJaiGajanan.
  ///
  /// In en, this message translates to:
  /// **'Shri Gajanan Jai Gajanan'**
  String get chantShriGajananJaiGajanan;

  /// No description provided for @namjapTitle.
  ///
  /// In en, this message translates to:
  /// **'Namjap'**
  String get namjapTitle;

  /// No description provided for @individualNamjapLabel.
  ///
  /// In en, this message translates to:
  /// **'Individual Namjap'**
  String get individualNamjapLabel;

  /// No description provided for @individualNamjapDescription.
  ///
  /// In en, this message translates to:
  /// **'Chant manually or listen to namjap for a specified duration or number of malas.'**
  String get individualNamjapDescription;

  /// No description provided for @groupNamjapLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Namjap'**
  String get groupNamjapLabel;

  /// No description provided for @groupNamjapDescription.
  ///
  /// In en, this message translates to:
  /// **'Join group namjap and contribute towards a shared sankalp.'**
  String get groupNamjapDescription;

  /// No description provided for @malaCountingTab.
  ///
  /// In en, this message translates to:
  /// **'Mala Counting'**
  String get malaCountingTab;

  /// No description provided for @timeBasedTab.
  ///
  /// In en, this message translates to:
  /// **'Time-based'**
  String get timeBasedTab;

  /// No description provided for @manualJapTab.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualJapTab;

  /// No description provided for @targetMalaCount.
  ///
  /// In en, this message translates to:
  /// **'Target (Malas)'**
  String get targetMalaCount;

  /// No description provided for @setTarget.
  ///
  /// In en, this message translates to:
  /// **'Set Target'**
  String get setTarget;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @totalMalasCompleted.
  ///
  /// In en, this message translates to:
  /// **'Total Malas Completed: {count}'**
  String totalMalasCompleted(int count);

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hrs'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Mins'**
  String get minutes;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @selectMalaCount.
  ///
  /// In en, this message translates to:
  /// **'Select Mala Count'**
  String get selectMalaCount;

  /// No description provided for @mala.
  ///
  /// In en, this message translates to:
  /// **'Mala'**
  String get mala;

  /// No description provided for @malas.
  ///
  /// In en, this message translates to:
  /// **'Malas'**
  String get malas;

  /// No description provided for @startPlay.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPlay;

  /// No description provided for @audioJapWillStart.
  ///
  /// In en, this message translates to:
  /// **'Audio jap will start'**
  String get audioJapWillStart;

  /// No description provided for @keepPhoneUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Please keep the phone unlocked to keep Naamjap playing'**
  String get keepPhoneUnlocked;

  /// No description provided for @tap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get tap;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to Edit'**
  String get tapToEdit;

  /// No description provided for @jap.
  ///
  /// In en, this message translates to:
  /// **'Jap'**
  String get jap;

  /// No description provided for @enterCustomTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter Target (e.g. 11)'**
  String get enterCustomTarget;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search stotras, bhajans...'**
  String get searchHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @japTimeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jap time completed!'**
  String get japTimeCompleted;

  /// No description provided for @targetMalasCompleted.
  ///
  /// In en, this message translates to:
  /// **'Target of {count} malas completed!'**
  String targetMalasCompleted(String count);

  /// No description provided for @templeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Temple Notifications'**
  String get templeNotifications;

  /// No description provided for @templeNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'(e.g., Volunteer requests, important announcements)'**
  String get templeNotificationsNote;

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

  /// No description provided for @googleSignInWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In on Web is not supported in this version. Please use the mobile app for admin access.'**
  String get googleSignInWebNotSupported;

  /// No description provided for @logoutInactivity.
  ///
  /// In en, this message translates to:
  /// **'Logged out due to inactivity.'**
  String get logoutInactivity;

  /// No description provided for @notificationRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get notificationRecently;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// No description provided for @errorRetrieveEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve user email.'**
  String get errorRetrieveEmail;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during sign in. Please try again.'**
  String get signInError;

  /// No description provided for @accessDeniedNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Your email is not authorized for admin access.'**
  String get accessDeniedNotAuthorized;

  /// No description provided for @notificationDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationDeleteTooltip;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @adminRestrictedArea.
  ///
  /// In en, this message translates to:
  /// **'Admin Restricted Area'**
  String get adminRestrictedArea;

  /// No description provided for @adminSignInInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please sign in with an authorized Google account to continue.'**
  String get adminSignInInstruction;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutLabel;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as'**
  String get loggedInAs;

  /// No description provided for @unknownAdmin.
  ///
  /// In en, this message translates to:
  /// **'Unknown Admin'**
  String get unknownAdmin;

  /// No description provided for @adminModules.
  ///
  /// In en, this message translates to:
  /// **'Admin Modules'**
  String get adminModules;

  /// No description provided for @templeNotificationsModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Temple Notifications'**
  String get templeNotificationsModuleTitle;

  /// No description provided for @templeNotificationsModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send manual push notifications to all users'**
  String get templeNotificationsModuleSubtitle;

  /// No description provided for @notificationSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully!'**
  String get notificationSentSuccess;

  /// No description provided for @notificationSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification: {error}'**
  String notificationSendError(String error);

  /// No description provided for @notAuthenticatedError.
  ///
  /// In en, this message translates to:
  /// **'Error: Not authenticated'**
  String get notAuthenticatedError;

  /// No description provided for @broadcastNotificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'This will send a push notification immediately to all users subscribed to Temple Notifications.'**
  String get broadcastNotificationInstruction;

  /// No description provided for @notificationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitleLabel;

  /// No description provided for @notificationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Volunteer Needed'**
  String get notificationTitleHint;

  /// No description provided for @notificationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get notificationTitleRequired;

  /// No description provided for @notificationMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Message'**
  String get notificationMessageLabel;

  /// No description provided for @notificationMessageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., We need 10 volunteers for Sunday Prasad! Sign up: https://example.com\n\nURLs will be automatically highlighted and tappable for users.'**
  String get notificationMessageHint;

  /// No description provided for @notificationMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message body'**
  String get notificationMessageRequired;

  /// No description provided for @broadcastButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Notification'**
  String get broadcastButtonLabel;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @notificationRetentionMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications will be automatically deleted in {days} days'**
  String notificationRetentionMessage(String days);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @twoWeeksBack.
  ///
  /// In en, this message translates to:
  /// **'{count} Weeks Back'**
  String twoWeeksBack(String count);

  /// No description provided for @threeWeeksBack.
  ///
  /// In en, this message translates to:
  /// **'{count} Weeks Back'**
  String threeWeeksBack(String count);

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @parayanCoordinationModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Parayan Coordination'**
  String get parayanCoordinationModuleTitle;

  /// No description provided for @parayanCoordinationModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage parayans'**
  String get parayanCoordinationModuleSubtitle;

  /// No description provided for @createParayanTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Parayan'**
  String get createParayanTitle;

  /// No description provided for @englishDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'English Details'**
  String get englishDetailsHeader;

  /// No description provided for @marathiDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'Marathi Details'**
  String get marathiDetailsHeader;

  /// No description provided for @parayanNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Name (English)'**
  String get parayanNameLabel;

  /// No description provided for @parayanNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Prakat Din Parayan'**
  String get parayanNameHint;

  /// No description provided for @parayanNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get parayanNameRequired;

  /// No description provided for @parayanNameMrLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Name (Marathi)'**
  String get parayanNameMrLabel;

  /// No description provided for @parayanNameMrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., प्रकट दिन पारायण'**
  String get parayanNameMrHint;

  /// No description provided for @parayanNameMrRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Marathi name'**
  String get parayanNameMrRequired;

  /// No description provided for @parayanDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get parayanDescriptionLabel;

  /// No description provided for @parayanDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'1-Day Parayan of Gajanan Vijay Granth on the auspicious occasion of Prakat Din'**
  String get parayanDescriptionHint;

  /// No description provided for @parayanDescriptionMrLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Marathi)'**
  String get parayanDescriptionMrLabel;

  /// No description provided for @parayanDescriptionMrHint.
  ///
  /// In en, this message translates to:
  /// **'प्रकट दिनाच्या शुभ प्रसंगी गजानन विजय ग्रंथाचे 1-दिवसीय पारायण'**
  String get parayanDescriptionMrHint;

  /// No description provided for @parayanDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Date'**
  String get parayanDateLabel;

  /// No description provided for @remindersFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminders will be sent at: 1:00 PM, 4:00 PM, and 7:00 PM'**
  String get remindersFixedLabel;

  /// No description provided for @parayanTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Type'**
  String get parayanTypeLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notification Time'**
  String get reminderTimeLabel;

  /// No description provided for @createParayanButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new Parayan'**
  String get createParayanButton;

  /// No description provided for @addParticipantLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Participant'**
  String get addParticipantLabel;

  /// No description provided for @nameAlphabetRegexError.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and spaces allowed'**
  String get nameAlphabetRegexError;

  /// No description provided for @parayanJoinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined Parayan successfully'**
  String get parayanJoinedSuccess;

  /// No description provided for @parayanUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Enrollment updated successfully'**
  String get parayanUpdatedSuccess;

  /// No description provided for @addHousehold.
  ///
  /// In en, this message translates to:
  /// **'Add Another Family'**
  String get addHousehold;

  /// No description provided for @addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add Another Participant'**
  String get addParticipant;

  /// No description provided for @submitAll.
  ///
  /// In en, this message translates to:
  /// **'Submit All'**
  String get submitAll;

  /// No description provided for @householdLabel.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get householdLabel;

  /// No description provided for @participantsAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Participants added successfully'**
  String get participantsAddedSuccess;

  /// No description provided for @assignedAdhyaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Assigned Adhyays'**
  String get assignedAdhyaysLabel;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @readingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reading Completed'**
  String get readingCompleted;

  /// No description provided for @submitReadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Submit Status'**
  String get submitReadingStatus;

  /// No description provided for @manualPingLabel.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder Notification - Coming Soon'**
  String get manualPingLabel;

  /// No description provided for @statsParticipants.
  ///
  /// In en, this message translates to:
  /// **'Total Participants: {count}'**
  String statsParticipants(int count);

  /// No description provided for @joinParayanLabel.
  ///
  /// In en, this message translates to:
  /// **'Join Parayan'**
  String get joinParayanLabel;

  /// No description provided for @signedUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed Up'**
  String get signedUpLabel;

  /// No description provided for @noActiveParayans.
  ///
  /// In en, this message translates to:
  /// **'No active parayans at the moment.'**
  String get noActiveParayans;

  /// No description provided for @adhyaysCompleted.
  ///
  /// In en, this message translates to:
  /// **'Adhyays Completed'**
  String get adhyaysCompleted;

  /// No description provided for @totalSignups.
  ///
  /// In en, this message translates to:
  /// **'Total Signups'**
  String get totalSignups;

  /// No description provided for @ongoingParayansLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Parayans'**
  String get ongoingParayansLabel;

  /// No description provided for @upcomingScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Schedule'**
  String get upcomingScheduleLabel;

  /// No description provided for @nextParayanLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Parayan'**
  String get nextParayanLabel;

  /// No description provided for @viewAllLabel.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllLabel;

  /// No description provided for @heroCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Start New Parayan Event'**
  String get heroCardTitle;

  /// No description provided for @parayanDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'Parayan Details'**
  String get parayanDetailsHeader;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @allAllocationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of participants'**
  String get allAllocationsLabel;

  /// No description provided for @adhyayAllocationTab.
  ///
  /// In en, this message translates to:
  /// **'Adhyay Allocation'**
  String get adhyayAllocationTab;

  /// No description provided for @myAllocationTab.
  ///
  /// In en, this message translates to:
  /// **'My Allocation'**
  String get myAllocationTab;

  /// No description provided for @upcomingParayanMessage.
  ///
  /// In en, this message translates to:
  /// **'Adhyays will be allocated once the Parayan enrollment starts'**
  String get upcomingParayanMessage;

  /// No description provided for @noSignupsFound.
  ///
  /// In en, this message translates to:
  /// **'No participants found yet'**
  String get noSignupsFound;

  /// No description provided for @statusUpcomingOneDay.
  ///
  /// In en, this message translates to:
  /// **'The parayan is on {date}. Participation is not yet open.'**
  String statusUpcomingOneDay(Object date);

  /// No description provided for @statusUpcomingMultiDay.
  ///
  /// In en, this message translates to:
  /// **'The parayan will start on {date}. Participation is not yet open.'**
  String statusUpcomingMultiDay(Object date);

  /// No description provided for @statusEnrolling.
  ///
  /// In en, this message translates to:
  /// **'Enrolling'**
  String get statusEnrolling;

  /// No description provided for @statusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get statusOngoing;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @parayanWillStartOn.
  ///
  /// In en, this message translates to:
  /// **'Parayan will start on {date}'**
  String parayanWillStartOn(String date);

  /// No description provided for @day1Label.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get day1Label;

  /// No description provided for @day2Label.
  ///
  /// In en, this message translates to:
  /// **'Day 2'**
  String get day2Label;

  /// No description provided for @day3Label.
  ///
  /// In en, this message translates to:
  /// **'Day 3'**
  String get day3Label;

  /// No description provided for @myAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'My Allocation Status'**
  String get myAllocationTitle;

  /// No description provided for @submitLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Parayan #'**
  String get activeLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed Parayan #'**
  String get completedLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get invalidPhone;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @participantsTab.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTab;

  /// No description provided for @participantsLabel.
  ///
  /// In en, this message translates to:
  /// **'PARTICIPANTS'**
  String get participantsLabel;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progressLabel;

  /// No description provided for @quickActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActionsLabel;

  /// No description provided for @adminAdhyaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhyays: {adhyays}'**
  String adminAdhyaysLabel(String adhyays);

  /// No description provided for @totalParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Participants'**
  String get totalParticipantsLabel;

  /// No description provided for @remindersStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminders Status'**
  String get remindersStatusLabel;

  /// No description provided for @reminderSentStatus.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get reminderSentStatus;

  /// No description provided for @reminderPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Yet to be sent'**
  String get reminderPendingStatus;

  /// No description provided for @updateStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Status'**
  String get updateStatusLabel;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get statusAllocated;

  /// No description provided for @statusEnrollingDesc.
  ///
  /// In en, this message translates to:
  /// **'Please sign-up for the parayan. It will start on {date}.'**
  String statusEnrollingDesc(Object date);

  /// No description provided for @statusAllocatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Adhyay allocation is complete. The parayan starts on {date}.'**
  String statusAllocatedDesc(Object date);

  /// No description provided for @statusUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get statusUpdateSuccess;

  /// No description provided for @successLabel.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group {group}'**
  String groupLabel(String group);

  /// No description provided for @adhyayCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'ADHYAY COMPLETION'**
  String get adhyayCompletionTitle;

  /// No description provided for @recentlyCompletedParayanLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently Completed Parayan'**
  String get recentlyCompletedParayanLabel;

  /// No description provided for @noCompletedParayans.
  ///
  /// In en, this message translates to:
  /// **'No recently completed parayans'**
  String get noCompletedParayans;

  /// No description provided for @upcomingParayansTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingParayansTab;

  /// No description provided for @completedParayansTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedParayansTab;

  /// No description provided for @parayanReminders.
  ///
  /// In en, this message translates to:
  /// **'Parayan Reminders'**
  String get parayanReminders;

  /// No description provided for @parayanRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications to remind you to read your assigned parayan adhyays'**
  String get parayanRemindersNote;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get createPlaylist;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename List'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get deletePlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get playlistName;

  /// No description provided for @addAarti.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAarti;

  /// No description provided for @removeAarti.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAarti;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToPlaylist;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get createNewPlaylist;

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'List Created'**
  String get playlistCreated;

  /// No description provided for @playlistRenamed.
  ///
  /// In en, this message translates to:
  /// **'List Renamed'**
  String get playlistRenamed;

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'List Deleted'**
  String get playlistDeleted;

  /// No description provided for @playlistNameRequired.
  ///
  /// In en, this message translates to:
  /// **'List name is required'**
  String get playlistNameRequired;

  /// No description provided for @playlistNameMaxChars.
  ///
  /// In en, this message translates to:
  /// **'List name must be under 50 characters'**
  String get playlistNameMaxChars;

  /// No description provided for @playlistNameAlphanumeric.
  ///
  /// In en, this message translates to:
  /// **'List name must be alphanumeric with spaces only'**
  String get playlistNameAlphanumeric;

  /// No description provided for @playlistAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A list with this name already exists'**
  String get playlistAlreadyExists;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to List'**
  String get addedToPlaylist;

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from List'**
  String get removedFromPlaylist;

  /// No description provided for @defaultPlaylistCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Default list cannot be deleted'**
  String get defaultPlaylistCannotBeDeleted;

  /// No description provided for @editEnrollmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Enrollment'**
  String get editEnrollmentLabel;

  /// No description provided for @updateEnrollmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Enrollment'**
  String get updateEnrollmentLabel;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @exportAllocations.
  ///
  /// In en, this message translates to:
  /// **'Export Status'**
  String get exportAllocations;

  /// No description provided for @exportingGroups.
  ///
  /// In en, this message translates to:
  /// **'Generating group snapshots...'**
  String get exportingGroups;

  /// No description provided for @seattleGajananMaharajParivar.
  ///
  /// In en, this message translates to:
  /// **'Seattle Gajanan Maharaj Parivar'**
  String get seattleGajananMaharajParivar;

  /// No description provided for @jaiGajanan.
  ///
  /// In en, this message translates to:
  /// **'Jai Gajanan'**
  String get jaiGajanan;

  /// No description provided for @parayanParticipant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get parayanParticipant;

  /// No description provided for @adhyaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Adhyays'**
  String get adhyaysLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @shareParayan.
  ///
  /// In en, this message translates to:
  /// **'Share Parayan'**
  String get shareParayan;

  /// No description provided for @deleteSignupLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Signup'**
  String get deleteSignupLabel;

  /// No description provided for @signupDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your signup has been deleted successfully.'**
  String get signupDeletedSuccess;

  /// No description provided for @deleteSignupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Signup?'**
  String get deleteSignupConfirmTitle;

  /// No description provided for @deleteSignupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your registration will be deleted and all members of your household will be removed from this parayan. Are you sure you want to proceed?'**
  String get deleteSignupConfirmMessage;

  /// No description provided for @duplicateNameError.
  ///
  /// In en, this message translates to:
  /// **'Duplicate name within a family'**
  String get duplicateNameError;

  /// No description provided for @maxMembersError.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 members allowed per family'**
  String get maxMembersError;

  /// No description provided for @householdMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get householdMembersLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @joiningSignupProgress.
  ///
  /// In en, this message translates to:
  /// **'Joining parayan...'**
  String get joiningSignupProgress;

  /// No description provided for @updatingSignupProgress.
  ///
  /// In en, this message translates to:
  /// **'Updating your signup...'**
  String get updatingSignupProgress;

  /// No description provided for @deletingSignupProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your signup...'**
  String get deletingSignupProgress;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @subscribingProgress.
  ///
  /// In en, this message translates to:
  /// **'Setting up notifications...'**
  String get subscribingProgress;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @unsubscribingProgress.
  ///
  /// In en, this message translates to:
  /// **'Removing notification subscriptions...'**
  String get unsubscribingProgress;

  /// No description provided for @exportSuffixAllocated.
  ///
  /// In en, this message translates to:
  /// **' - Adhyay Allocation'**
  String get exportSuffixAllocated;

  /// No description provided for @exportSuffixOngoing.
  ///
  /// In en, this message translates to:
  /// **' - Current Status'**
  String get exportSuffixOngoing;

  /// No description provided for @exportSuffixCompleted.
  ///
  /// In en, this message translates to:
  /// **' Completed. Jai Gajanan 🙏🏻'**
  String get exportSuffixCompleted;

  /// No description provided for @exportToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Export to Calendar'**
  String get exportToCalendar;

  /// No description provided for @shareParayanAction.
  ///
  /// In en, this message translates to:
  /// **'Join this Parayan'**
  String get shareParayanAction;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get shareLink;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this list?'**
  String get deletePlaylistConfirm;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @forcedUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A mandatory update is required to continue using the app. Please update to the latest version.'**
  String get forcedUpdateMessage;

  /// No description provided for @recommendedUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available with improvements and bug fixes. Would you like to update now?'**
  String get recommendedUpdateMessage;

  /// No description provided for @latestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersionLabel;

  /// No description provided for @currentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersionLabel;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @noParayansFound.
  ///
  /// In en, this message translates to:
  /// **'No parayans found for the current year'**
  String get noParayansFound;

  /// No description provided for @joinCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Join Code'**
  String get joinCodeTitle;

  /// No description provided for @joinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-character code'**
  String get joinCodeHint;

  /// No description provided for @invalidJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Join Code!'**
  String get invalidJoinCode;

  /// No description provided for @copyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Invite Link'**
  String get copyInviteLink;

  /// No description provided for @copyJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Join Code'**
  String get copyJoinCode;

  /// No description provided for @joinCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Join Code copied to clipboard'**
  String get joinCodeCopied;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite Link copied to clipboard'**
  String get inviteLinkCopied;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get joinCodeLabel;

  /// No description provided for @shareWithCode.
  ///
  /// In en, this message translates to:
  /// **'Share with Code'**
  String get shareWithCode;

  /// No description provided for @guruPushyaEndDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please set the end date and time for Guru Pushya parayan'**
  String get guruPushyaEndDateRequired;

  /// No description provided for @confirmCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletionTitle;

  /// No description provided for @confirmCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Have you completed reading the assigned adhyay?'**
  String get confirmCompletionMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @readingProgressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reading progress updated'**
  String get readingProgressUpdated;

  /// No description provided for @homeStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Kids Stories'**
  String get homeStoriesTitle;

  /// No description provided for @storiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get storiesTitle;

  /// No description provided for @audiosTitle.
  ///
  /// In en, this message translates to:
  /// **'Audios'**
  String get audiosTitle;

  /// No description provided for @videosTitle.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosTitle;

  /// No description provided for @reportTypoTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Typo'**
  String get reportTypoTitle;

  /// No description provided for @reportTypoLabel.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Text'**
  String get reportTypoLabel;

  /// No description provided for @suggestedCorrectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested Correction (Optional)'**
  String get suggestedCorrectionLabel;

  /// No description provided for @reportTypoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report has been submitted.'**
  String get reportTypoSuccess;

  /// No description provided for @reportTypoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report. Please try again.'**
  String get reportTypoError;

  /// No description provided for @adminTypoReportsModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Typo Reports'**
  String get adminTypoReportsModuleTitle;

  /// No description provided for @adminTypoReportsModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage and fix content typos'**
  String get adminTypoReportsModuleSubtitle;

  /// No description provided for @typoNotificationToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Typo Report Notifications'**
  String get typoNotificationToggleLabel;

  /// No description provided for @markAsFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Fixed'**
  String get markAsFixed;

  /// No description provided for @selectTextToReportHint.
  ///
  /// In en, this message translates to:
  /// **'Please select the typo text first, then click this icon to report it.'**
  String get selectTextToReportHint;

  /// No description provided for @typoReportConfirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure the content has been updated and you want to delete this report?'**
  String get typoReportConfirmDeleteMessage;

  /// No description provided for @typoReportDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get typoReportDeleteButton;

  /// No description provided for @typoReportIncorrectTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Text:'**
  String get typoReportIncorrectTextLabel;

  /// No description provided for @typoReportSuggestedCorrectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested Correction:'**
  String get typoReportSuggestedCorrectionLabel;

  /// No description provided for @typoReportNoSuggestion.
  ///
  /// In en, this message translates to:
  /// **'(No suggestion provided)'**
  String get typoReportNoSuggestion;

  /// No description provided for @typoReportNoPendingReports.
  ///
  /// In en, this message translates to:
  /// **'No typos reported'**
  String get typoReportNoPendingReports;

  /// No description provided for @typoReportPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path: {path}'**
  String typoReportPathLabel(String path);

  /// No description provided for @parayanGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Parayan Group'**
  String get parayanGroupLabel;

  /// No description provided for @statusOngoingDesc.
  ///
  /// In en, this message translates to:
  /// **'The parayan is currently ongoing. Please complete your assigned adhyays.'**
  String get statusOngoingDesc;

  /// No description provided for @statusCompletedDesc.
  ///
  /// In en, this message translates to:
  /// **'The parayan has been completed. Jai Gajanan!'**
  String get statusCompletedDesc;

  /// No description provided for @adminParayanGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Parayan Groups'**
  String get adminParayanGroupTitle;

  /// No description provided for @parayanAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A Parayan event already exists for this date and type in this group.'**
  String get parayanAlreadyExists;

  /// No description provided for @useMobileAppForParayan.
  ///
  /// In en, this message translates to:
  /// **'Please use the mobile app for Parayan'**
  String get useMobileAppForParayan;

  /// No description provided for @groupNamjapModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Namjap'**
  String get groupNamjapModuleTitle;

  /// No description provided for @groupNamjapModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage group namjap and participant stats'**
  String get groupNamjapModuleSubtitle;

  /// No description provided for @createGroupNamjapTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group Namjap'**
  String get createGroupNamjapTitle;

  /// No description provided for @groupNamjapDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Namjap'**
  String get groupNamjapDashboardTitle;

  /// No description provided for @groupNamjapCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed Group Namjaps'**
  String get groupNamjapCompleted;

  /// No description provided for @groupNamjapRecentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recently Completed Group Namjaps'**
  String get groupNamjapRecentlyCompleted;

  /// No description provided for @groupNamjapOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Group Namjaps'**
  String get groupNamjapOngoing;

  /// No description provided for @groupNamjapUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Group Namjaps'**
  String get groupNamjapUpcoming;

  /// No description provided for @groupNamjapNoOngoing.
  ///
  /// In en, this message translates to:
  /// **'No active group namjaps currently'**
  String get groupNamjapNoOngoing;

  /// No description provided for @groupNamjapNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming group namjaps currently'**
  String get groupNamjapNoUpcoming;

  /// No description provided for @groupNamjapNoCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed group namjaps yet'**
  String get groupNamjapNoCompleted;

  /// No description provided for @groupNamjapEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get groupNamjapEventDetails;

  /// No description provided for @groupNamjapJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get groupNamjapJoinCode;

  /// No description provided for @groupNamjapProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get groupNamjapProgress;

  /// No description provided for @groupNamjapParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get groupNamjapParticipants;

  /// No description provided for @groupNamjapNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants joined yet.'**
  String get groupNamjapNoParticipants;

  /// No description provided for @groupNamjapNameEn.
  ///
  /// In en, this message translates to:
  /// **'Event Name (English)'**
  String get groupNamjapNameEn;

  /// No description provided for @groupNamjapNameMr.
  ///
  /// In en, this message translates to:
  /// **'Event Name (Marathi)'**
  String get groupNamjapNameMr;

  /// No description provided for @groupNamjapSankalpEn.
  ///
  /// In en, this message translates to:
  /// **'Sankalp (English)'**
  String get groupNamjapSankalpEn;

  /// No description provided for @groupNamjapSankalpMr.
  ///
  /// In en, this message translates to:
  /// **'Sankalp (Marathi)'**
  String get groupNamjapSankalpMr;

  /// No description provided for @groupNamjapTargetCount.
  ///
  /// In en, this message translates to:
  /// **'Target Count'**
  String get groupNamjapTargetCount;

  /// No description provided for @groupNamjapStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get groupNamjapStartDate;

  /// No description provided for @groupNamjapEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get groupNamjapEndDate;

  /// No description provided for @groupNamjapCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group Namjap created successfully!'**
  String get groupNamjapCreateSuccess;

  /// No description provided for @groupNamjapRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get groupNamjapRequired;

  /// No description provided for @groupNamjapMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get groupNamjapMustBeNumber;

  /// No description provided for @groupNamjapTargetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Target: '**
  String get groupNamjapTargetPrefix;

  /// No description provided for @groupNamjapAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved: '**
  String get groupNamjapAchieved;

  /// No description provided for @groupNamjapOf.
  ///
  /// In en, this message translates to:
  /// **' of '**
  String get groupNamjapOf;

  /// No description provided for @groupNamjapMantra.
  ///
  /// In en, this message translates to:
  /// **'Mantra'**
  String get groupNamjapMantra;

  /// No description provided for @groupNamjapTotalParticipants.
  ///
  /// In en, this message translates to:
  /// **'PARTICIPANTS'**
  String get groupNamjapTotalParticipants;

  /// No description provided for @groupNamjapAchievedLabel.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVED'**
  String get groupNamjapAchievedLabel;

  /// No description provided for @groupNamjapQuickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get groupNamjapQuickActions;

  /// No description provided for @groupNamjapShare.
  ///
  /// In en, this message translates to:
  /// **'Share Namjap'**
  String get groupNamjapShare;

  /// No description provided for @groupNamjapExportStatus.
  ///
  /// In en, this message translates to:
  /// **'Export Status'**
  String get groupNamjapExportStatus;

  /// No description provided for @groupNamjapSankalpLabel.
  ///
  /// In en, this message translates to:
  /// **'Sankalp'**
  String get groupNamjapSankalpLabel;

  /// No description provided for @groupNamjapStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Namjap Status'**
  String get groupNamjapStatusLabel;

  /// No description provided for @groupNamjapEventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get groupNamjapEventNotFound;

  /// No description provided for @groupNamjapFailedToCapture.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture screenshot'**
  String get groupNamjapFailedToCapture;

  /// No description provided for @groupNamjapStatusExport.
  ///
  /// In en, this message translates to:
  /// **'Namjap Status Export'**
  String get groupNamjapStatusExport;

  /// No description provided for @groupNamjapSharePrefix.
  ///
  /// In en, this message translates to:
  /// **'Join our Namjap'**
  String get groupNamjapSharePrefix;

  /// No description provided for @groupNamjapShareLinkPrefix.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get groupNamjapShareLinkPrefix;

  /// No description provided for @groupNamjapTableColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groupNamjapTableColName;

  /// No description provided for @groupNamjapTableColPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get groupNamjapTableColPhone;

  /// No description provided for @groupNamjapTableColTotalChants.
  ///
  /// In en, this message translates to:
  /// **'Namjap'**
  String get groupNamjapTableColTotalChants;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @totalCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Count'**
  String get totalCountLabel;

  /// No description provided for @myTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'My Total'**
  String get myTotalLabel;

  /// No description provided for @manualEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Namjap Count'**
  String get manualEntryLabel;

  /// No description provided for @mantraLabel.
  ///
  /// In en, this message translates to:
  /// **'Mantra'**
  String get mantraLabel;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRangeLabel;

  /// No description provided for @groupNamjapSubmitCount.
  ///
  /// In en, this message translates to:
  /// **'Submit Namjap Count: {count}'**
  String groupNamjapSubmitCount(String count);

  /// No description provided for @dashami.
  ///
  /// In en, this message translates to:
  /// **'Dashami'**
  String get dashami;

  /// No description provided for @ekadashi.
  ///
  /// In en, this message translates to:
  /// **'Ekadashi'**
  String get ekadashi;

  /// No description provided for @dwadashi.
  ///
  /// In en, this message translates to:
  /// **'Dwadashi'**
  String get dwadashi;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get memberName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @deleteSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signup deleted successfully'**
  String get deleteSignupSuccess;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Signup'**
  String get editLabel;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Signup'**
  String get updateLabel;

  /// No description provided for @deleteSignupConfirmMessageNamjap.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your signup for this Namjap?'**
  String get deleteSignupConfirmMessageNamjap;

  /// No description provided for @groupNamjapTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get groupNamjapTimezone;

  /// No description provided for @upcomingActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming / Active'**
  String get upcomingActiveTab;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// No description provided for @activeGroups.
  ///
  /// In en, this message translates to:
  /// **'Active Groups'**
  String get activeGroups;

  /// No description provided for @availableGroups.
  ///
  /// In en, this message translates to:
  /// **'Available Groups'**
  String get availableGroups;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Long press to drag and reorder'**
  String get dragToReorder;

  /// No description provided for @noActiveGroups.
  ///
  /// In en, this message translates to:
  /// **'You have no active groups. Add one from below.'**
  String get noActiveGroups;

  /// No description provided for @groupAdded.
  ///
  /// In en, this message translates to:
  /// **'Group added'**
  String get groupAdded;

  /// No description provided for @groupRemoved.
  ///
  /// In en, this message translates to:
  /// **'Group removed'**
  String get groupRemoved;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Shree Gajanan Maharaj Sevekari'**
  String get onboardingWelcome;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select the Gajanan Maharaj group(s) you are associated with. You can always change this later in Settings.'**
  String get onboardingDescription;

  /// No description provided for @finishOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get finishOnboarding;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe for other groups'**
  String get swipeHint;
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
