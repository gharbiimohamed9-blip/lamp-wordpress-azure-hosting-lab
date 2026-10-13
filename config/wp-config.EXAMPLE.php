<?php
// EXEMPLE : le vrai wp-config.php n'est JAMAIS publié (voir .gitignore)
define( 'DB_NAME',     'wp_monsite' );
define( 'DB_USER',     'wp_user' );
define( 'DB_PASSWORD', 'CHANGE_ME' );
define( 'DB_HOST',     'localhost' );
define( 'DB_CHARSET',  'utf8mb4' );
// Salts : générer avec  curl -s https://api.wordpress.org/secret-key/1.1/salt/
