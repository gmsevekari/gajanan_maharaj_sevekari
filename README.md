# gajanan_maharaj_sevekari

Gajanan Maharaj Sevekari App

## Getting Started

This project is a a Flutter application for Gajanan Maharaj Sevekari app.

Git repo: https://github.com/gmsevekari/gajanan_maharaj_sevekari/commits/main/

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Prerequisites: Flutter SDK Setup

Before you can set up the project, you need to have the Flutter SDK installed on your computer.

### For macOS

1.  **Download the Flutter SDK:**
    *   Go to the [Flutter SDK releases page](https://docs.flutter.dev/get-started/install/macos#get-sdk).
    *   Download the latest stable release for macOS (select the ARM64 or Intel version based on your Mac\'s processor).

2.  **Extract the SDK:**
    *   Open your Terminal.
    *   Navigate to the directory where you want to install Flutter (e.g., `cd ~/development`).
    *   Unzip the downloaded file: `unzip ~/Downloads/flutter_macos_*.zip`

3.  **Update Your Path:**
    *   Open your shell\'s configuration file (`~/.zshrc` for Zsh, which is the default on modern macOS).
    *   Add the following line to the end of the file, replacing `[PATH_TO_FLUTTER_GIT_DIRECTORY]` with the actual path to where you unzipped Flutter:
        `export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"`
    *   Save the file and restart your terminal.

4.  **Verify Installation:**
    *   Run `flutter doctor`. This command checks your environment and displays a report of the status of your Flutter installation. Address any issues it reports.

### For Windows

1.  **Download the Flutter SDK:**
    *   Go to the [Flutter SDK releases page](https://docs.flutter.dev/get-started/install/windows#get-sdk).
    *   Download the latest stable release for Windows.

2.  **Extract the SDK:**
    *   Extract the downloaded ZIP file to a location like `C:\src\flutter`. Do not install Flutter in a directory like `C:\Program Files\` that requires elevated privileges.

3.  **Update Your Path:**
    *   From the Start search bar, type 'env' and select **Edit the system environment variables**.
    *   Under "User variables" check if there is an entry called **Path**:
        *   If the entry exists, append the full path to `flutter\bin` using `;` as a separator from existing values.
        *   If the entry does not exist, create a new user variable named `Path` with the full path to `flutter\bin` as its value.
    *   Restart any open Command Prompt or PowerShell windows for the change to take effect.

4.  **Verify Installation:**
    *   Open a new Command Prompt or PowerShell window and run `flutter doctor`. This command checks your environment and displays a report. Address any issues it reports.

## Project Setup

*   **Android Studio:** Ensure you have the latest version of Android Studio installed, along with the Flutter and Dart plugins.

*   **Clone the Project:** You can get the project source code by cloning the repository using either the Terminal or Android Studio.

    *   **Using Terminal:**
        1.  Open your terminal or command prompt.
        2.  Navigate to your preferred projects folder (e.g., `cd "C:\Users\YourUser\AndroidStudioProjects"` or `cd ~/Documents/AndroidStudioProjects`).
        3.  Clone the repository using the following command:
            ```sh
            git clone https://github.com/gmsevekari/gajanan_maharaj_sevekari.git
            ```
        4.  Navigate into the newly created project directory:
            ```sh
            cd gajanan_maharaj_sevekari
            ```
        5.  Open the project in Android Studio.

    *   **Using Android Studio:**
        1.  From the Welcome Screen, click **Get from VCS**. (If a project is already open, go to **File > New > Project from Version Control...**).
        2.  Enter the repository URL: `https://github.com/gmsevekari/gajanan_maharaj_sevekari.git`
        3.  Choose the local directory where you want to save the project.
        4.  Click **Clone**. Android Studio will open the project automatically.

*   **Install Dependencies:** Once the project is open, a "Pub get" prompt will appear at the top of the `pubspec.yaml` file. Click it to install all the required project dependencies. You can also run the following command in the Android Studio terminal:
    ```sh
    flutter pub get
    ```

## Configuring Git Permissions to Push Changes

To contribute code to the repository, you need to authenticate with GitHub. The recommended and most secure method is to use a **Personal Access Token (PAT)** instead of your account password.

### Step 1: Create a Personal Access Token (PAT) on GitHub

1.  **Go to your GitHub Settings:**
    *   Click on your profile picture in the top-right corner of GitHub and select **Settings**.
2.  **Navigate to Developer Settings:**
    *   In the left sidebar, scroll down and click on **Developer settings**.
3.  **Go to Personal Access Tokens:**
    *   In the left sidebar, click on **Personal access tokens** and select **Tokens (classic)**.
4.  **Generate a New Token:**
    *   Click the **Generate new token** button.
    *   In the **Note** field, give your token a descriptive name that identifies you and the machine (e.g., "YourName-MacBook-GajananApp"). **Each developer on the team should create their own personal token.**
    *   Set the **Expiration** for the token. For security, it is recommended to set an expiration date (e.g., 30 or 90 days).
    *   Under **Select scopes**, check the `repo` box. This will grant the token the necessary permissions to pull and push code.
    *   Click **Generate token** at the bottom.

5.  **Copy Your Token:**
    *   **Important:** Copy your new token immediately. You will **not** be able to see it again after you navigate away from this page. Save it in a secure location, like a password manager.

### Step 2: Use the Token to Push Changes

When you perform a `git push` from your terminal or from within Android Studio for the first time, you will be prompted for your username and password.

*   **Username:** Enter your GitHub username.
*   **Password:** **Do not** use your GitHub account password. Instead, paste the **Personal Access Token (PAT)** you copied in the step above.

Your machine will securely cache these credentials (in the macOS Keychain or Windows Credential Manager), so you should not have to enter them for every push.
