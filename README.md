# PHP Authentication Class

SunAuth is an advanced PHP authentication class.

The goal of this class is to let you; authenticate users/admins against your own database table, open and track database backed sessions, and secure the login flow with brute force protection, remember-me tokens, role checks, password reset, and two factor authentication.

`Technical Document:` https://www.deepwiki.com/msbatal/PHP-Authentication-Class

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/msbatal/PHP-Authentication-Class)

<hr>

`Database` attribute: The database connection SunAuth uses for every query. This value may be a `SunDB` instance, a `PDO` object, or a connection parameters array (same array that `SunDB` accepts). SunAuth always talks to the database through `SunDB` internally.

`Identifier` attribute: The user table column used to log in with. This value may be `email`, `username`, or any unique column on your user table. It is set with the `identifier` config option.

`Config` attribute: An optional array that overrides the defaults. This value may set the user table name, the column mapping (`id`, `username`, `email`, `password`, `role`, `status`, `twofa`), session/remember/reset lifetimes, lockout thresholds, and the table prefix.

<hr>

### Installation

To utilize this class, first import SunDB.php and SunAuth.php into your project, and require them.
SunAuth requires PHP 7.4+ and the SunDB class to work.

```php
require_once ('SunDB.php');
require_once ('SunAuth.php');
```

> **Note:** SunDB is a separate dependency and is **not** bundled in this repository. Download `SunDB.php` from its own GitHub repository and add it to your project alongside `SunAuth.php`:
> <a href="https://github.com/msbatal/PHP-PDO-Database-Class" target="_blank">https://github.com/msbatal/PHP-PDO-Database-Class</a>

Then run the support tables SQL once (creates the `sun_sessions`, `sun_login_attempts`, `sun_remember_tokens`, and `sun_password_resets` tables). Your own user table is not created here.

```php
// import SunAuth.sql into your database (via phpMyAdmin, mysql client, etc.)
```

### Initialization

Using a connection parameters array:

```php
$auth = new SunAuth(['driver' => 'mysql', 'host' => 'localhost', 'dbname' => 'test', 'username' => 'root', 'password' => 'root']);
```

Using an existing SunDB instance (recommended when you already use SunDB):

```php
$db = new SunDB('mysql', 'localhost', 'root', 'root', 'test');
$auth = new SunAuth($db);
```

Using an existing PDO object:

```php
$pdo = new PDO('mysql:host=localhost;dbname=test', 'root', 'root');
$auth = new SunAuth($pdo);
```

With configuration overrides:

```php
$auth = new SunAuth($db, [
    'table'      => 'users',   // your user table name
    'identifier' => 'email',   // column used to log in with
    'columns'    => [          // map only the columns that differ from the defaults
        'password' => 'pass',
        'role'     => 'user_role'
    ]
]);
```

### Registration

Register a new user (the password is hashed automatically, duplicates are rejected).

```php
$auth = new SunAuth($db);
$userId = $auth->register([
    'email'    => 'sample@domain.com',
    'password' => 'secret123',        // plain password, hashed with password_hash()
    'role'     => 'user'
]);
if ($userId !== false) {
    echo 'Registered with id: ' . $userId;
} else {
    echo $auth->lastError(); // e.g. duplicate identifier
}
```

### Login

Authenticate a user and open a session.

```php
$auth = new SunAuth($db);
if ($auth->login('sample@domain.com', 'secret123')) {
    echo 'Logged in.';
} else {
    echo $auth->lastError(); // invalid credentials, inactive, or locked out
}
```

Login with a persistent "remember me" cookie:

```php
$auth = new SunAuth($db);
$auth->login('sample@domain.com', 'secret123', true); // third param enables remember-me
```

### Checking Authentication

Check whether a user is logged in and read the current user.

```php
$auth = new SunAuth($db);
if ($auth->isLoggedIn()) {          // alias: $auth->check()
    $user = $auth->user();          // current user record (array) or null
    $id   = $auth->id();            // current user id (int) or null
    echo 'Welcome ' . $user['email'];
} else {
    echo 'Not logged in.';
}
```

### Verify Password

Verify a user's credentials without opening a session.

```php
$auth = new SunAuth($db);
$result = $auth->verifyPassword('sample@domain.com', 'secret123');
if ($result == true) {
    echo 'Password is correct.';
} else {
    echo 'Password is wrong.';
}
```

### Check User Existence

```php
$auth = new SunAuth($db);
if ($auth->userExists('sample@domain.com')) {
    echo 'User exists.';
}
```

### Logout

```php
$auth = new SunAuth($db);
$auth->logout();       // log out this device
$auth->logout(true);   // log out every device (all sessions of the user)
```

### Brute Force Protection

Failed attempts are counted per identifier + IP, and the account is locked after the threshold (default 5 attempts, 15 minutes lock).

```php
$auth = new SunAuth($db);
if ($auth->isLocked('sample@domain.com')) {
    $status = $auth->lockoutStatus('sample@domain.com'); // ['locked' => bool, 'remaining' => sec, 'attempts' => n]
    echo 'Locked for ' . $status['remaining'] . ' seconds.';
}
```

### Roles & Permissions

Requires a `role` column on your user table (auto-disabled when the column is missing).

> **Note:** SunAuth only performs a **role check** — it reads the `role` value from the database and tells you whether the current user has that role. It does **not** define roles or their permissions. There is no fixed list of roles; any string in the `role` column is a valid role (only `adminRole` is treated specially, for the `isAdmin()` shortcut). **What each role is allowed to do is entirely up to you:** decide it in your own PHP files with `if` checks around the methods below. SunAuth answers "does this user have role X?"; your code decides "what role X can do".

```php
$auth = new SunAuth($db);
echo $auth->role();               // current user role, e.g. 'admin'
if ($auth->isAdmin()) { ... }     // role == config 'adminRole'
if ($auth->hasRole('editor')) { ... }
$auth->requireRole('admin');      // throws an exception when the role does not match
```

You define the capabilities of each role yourself, outside the class:

```php
$auth = new SunAuth($db);
// SunAuth only confirms the role; YOU decide what that role can do.
if ($auth->hasRole('editor')) {
    // your rule: editors may edit posts
    showPostEditor();
}
if ($auth->isAdmin()) {
    // your rule: admins may delete users
    showDeleteButton();
}
```

### Password Reset

Create a reset token (email delivery is up to your application), then reset with it.

```php
$auth = new SunAuth($db);
$token = $auth->createResetToken('sample@domain.com'); // send this token to the user by email
// ... later, from the reset form ...
if ($auth->verifyResetToken($token) !== false) {       // token valid and not expired
    $auth->resetPassword($token, 'newSecret123');      // sets the new password, clears all sessions
}
```

### Change Password

```php
$auth = new SunAuth($db);
if ($auth->changePassword($userId, 'secret123', 'newSecret123')) {
    echo 'Password changed.';
} else {
    echo $auth->lastError(); // current password does not match
}
```

### Two Factor Authentication (2FA)

Requires a `twofa_secret` column on your user table. Uses TOTP (compatible with Google Authenticator, Authy, etc.), no external library.

Enable 2FA for a user (returns the secret and an `otpauth://` URI for the QR code):

```php
$auth = new SunAuth($db);
$data = $auth->enableTwoFactor($userId);
echo $data['secret']; // base32 secret
echo $data['uri'];    // otpauth:// uri, render it as a QR code
```

Confirm/verify a code:

```php
$auth = new SunAuth($db);
if ($auth->verifyTwoFactorCode($userId, '123456')) {
    echo 'Code is valid.';
}
$auth->disableTwoFactor($userId); // turn 2FA off
```

Login flow with 2FA (when a user has 2FA enabled, `login()` opens a pending session):

```php
$auth = new SunAuth($db);
$auth->login('sample@domain.com', 'secret123');
if ($auth->pendingTwoFactor() !== false) {   // waiting for the 2FA code
    if ($auth->verifyTwoFactor('123456')) {  // promotes the pending session
        echo 'Fully logged in.';
    }
}
```

### Session Management

List and revoke the active sessions of a user (multi device).

```php
$auth = new SunAuth($db);
$list = $auth->sessions();          // active sessions of the current user
foreach ($list as $session) {
    echo $session['ip'] . ' - ' . $session['user_agent'];
}
$auth->destroySession($sessionId);  // revoke a specific device by session id
$auth->regenerate();                // regenerate the PHP session id (session fixation defense)
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `table` | `users` | User table name |
| `columns` | see below | User table column mapping |
| `identifier` | `email` | Column used to log in with |
| `activeStatus` | `1` | Value of the `status` column for an active account |
| `prefix` | `sun_` | Prefix for the support tables |
| `sessionLifetime` | `7200` | Active session lifetime (seconds) |
| `rememberLifetime` | `1209600` | Remember-me lifetime (seconds, 14 days) |
| `resetLifetime` | `3600` | Password reset token lifetime (seconds) |
| `maxAttempts` | `5` | Failed attempts before lockout |
| `lockoutTime` | `900` | Lockout duration (seconds) |
| `adminRole` | `admin` | Role value that identifies an administrator |
| `cookieName` | `sun_remember` | Remember-me cookie name |
| `sessionKey` | `sun_auth` | `$_SESSION` key holding the session token |
| `issuer` | `SunAuth` | Issuer label for the 2FA otpauth uri |

Default column mapping: `id`, `username`, `email`, `password`, `role`, `status`, `twofa_secret`.
Missing optional columns (`role`, `status`, `twofa_secret`) automatically disable their related features.

### Help

Passwords are stored with PHP's `password_hash()` / `password_verify()`. For more information; Please visit the PHP.Net documentation's "Password Hashing" section.

<a href="https://www.php.net/manual/en/book.password.php" target="_blank">Password Hashing</a>

<a href="https://github.com/msbatal/PHP-PDO-Database-Class" target="_blank">SunDB (PHP PDO Database Class)</a>
