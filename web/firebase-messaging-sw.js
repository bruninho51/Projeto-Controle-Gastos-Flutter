importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyCYTtf6bacLqG0X690dYPY9olg9xnxXesA',
  appId:             '1:1004439512234:web:324c1c04ab8380e82d9cd3',
  messagingSenderId: '1004439512234',
  projectId:         'orcamentos-de1ba',
  authDomain:        'orcamentos-de1ba.firebaseapp.com',
  storageBucket:     'orcamentos-de1ba.firebasestorage.app',
});

const messaging = firebase.messaging();

// notificações em background (app fechado ou em outra aba)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const title = payload.notification?.title ?? 'Nova notificação';
  const body  = payload.notification?.body  ?? '';
  const icon  = payload.notification?.icon  ?? '/icons/Icon-192.png';

  self.registration.showNotification(title, { body, icon });
});