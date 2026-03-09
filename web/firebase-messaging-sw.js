importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-messaging-compat.js");

const firebaseConfig = {
    apiKey: "AIzaSyD-d9bKzLkDylQiOT5_ZsqbejsB-nfmjBE",
    appId: "1:33491188906:web:7aa4a94b03374815c6e4d3",
    messagingSenderId: "33491188906",
    projectId: "app-event-calendar",
    authDomain: "app-event-calendar.firebaseapp.com",
    storageBucket: "app-event-calendar.firebasestorage.app",
    measurementId: "G-HXZ0FDWKW5",
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();
