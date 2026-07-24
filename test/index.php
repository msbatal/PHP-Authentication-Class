<?php

    require_once ('SunDB.php');   // Call 'SunDB' class (dependency, see github.com/msbatal/PHP-PDO-Database-Class)
    require_once ('SunAuth.php'); // Call 'SunAuth' class

    // Import test.sql into your database first. SunAuth needs MySQL.
    // Don't forget to change dbname, username, and password below.
    $db = new SunDB(['driver' => 'mysql', 'host' => 'localhost', 'port' => 3306, 'dbname' => 'test', 'username' => 'test', 'password' => '1234', 'charset' => 'utf8']);

    // Initialize SunAuth (login with the "email" column of the "users" table)
    $auth = new SunAuth($db, [
        'table'      => 'users',
        'identifier' => 'email'
    ]);

    // Demo credentials seeded by test.sql -> email: demo@sunauth.test / password: demo1234


    // Example for Login (opens a database backed session)
    if ($auth->login('demo@sunauth.test', 'demo1234')) {
        $user = $auth->user();
        echo 'Logged in as: '.$user['email'].'<br>'.'Role: '.$auth->role().'<br>'.'User ID: '.$auth->id();
    } else {
        echo 'Login failed: '.$auth->lastError(); // invalid credentials, inactive account, or locked out
    }


    /*
    // Example for Login with "Remember Me" (persistent cookie)
    if ($auth->login('demo@sunauth.test', 'demo1234', true)) { // third param sets the remember-me cookie
        echo 'Logged in and remembered.';
    }
    */


    /*
    // Example for Registration (password is hashed automatically, duplicates rejected)
    $userId = $auth->register([
        'email'    => 'newuser@sunauth.test',
        'password' => 'secret123',
        'username' => 'newuser',
        'role'     => 'user'
    ]);
    if ($userId !== false) {
        echo 'Registered with ID: '.$userId;
    } else {
        echo 'Register failed: '.$auth->lastError();
    }
    */


    /*
    // Example for Check User Existence
    if ($auth->userExists('demo@sunauth.test')) {
        echo 'User exists.';
    } else {
        echo 'User not found.';
    }
    */


    /*
    // Example for Verify Password (checks credentials without opening a session)
    $result = $auth->verifyPassword('demo@sunauth.test', 'demo1234');
    echo $result ? 'Password is correct.' : 'Password is wrong.';
    */


    /*
    // Example for Checking Authentication
    if ($auth->isLoggedIn()) {          // alias: $auth->check()
        $user = $auth->user();          // current user record (array) or null
        echo 'Current user: '.$user['email'].' (ID: '.$auth->id().')';
    } else {
        echo 'Not logged in.';
    }
    */


    /*
    // Example for Logout
    $auth->logout();      // log out this device
    // $auth->logout(true); // log out every device (all sessions of the user)
    echo 'Logged out.';
    */


    /*
    // Example for Session Management (list active sessions of the current user)
    $auth->login('demo@sunauth.test', 'demo1234'); // must be logged in first
    $sessions = $auth->sessions();
    foreach ($sessions as $session) {
        echo 'Session #'.$session['id'].' - IP: '.$session['ip'].' - Last: '.$session['last_activity'].'<br>';
    }
    // $auth->destroySession($sessionId); // revoke a specific device by session id
    // $auth->regenerate();               // regenerate the PHP session id (session fixation defense)
    */


    /*
    // Example for Brute Force Protection (lockout after too many failed attempts)
    if ($auth->isLocked('demo@sunauth.test')) {
        $status = $auth->lockoutStatus('demo@sunauth.test'); // ['locked' => bool, 'remaining' => sec, 'attempts' => n]
        echo 'Account locked. Remaining: '.$status['remaining'].' seconds (attempts: '.$status['attempts'].').';
    } else {
        echo 'Account is not locked.';
    }
    */


    /*
    // Example for Roles (SunAuth only checks the role; YOU decide what each role can do)
    $auth->login('demo@sunauth.test', 'demo1234');
    echo 'Role: '.$auth->role().'<br>';                 // reads the "role" column
    echo 'Is admin: '.($auth->isAdmin() ? 'yes' : 'no').'<br>';   // role == config 'adminRole'
    echo 'Has role editor: '.($auth->hasRole('editor') ? 'yes' : 'no').'<br>';
    // $auth->requireRole('admin'); // throws an exception when the role does not match
    */


    /*
    // Example for Password Reset (create token, verify it, then reset)
    $token = $auth->createResetToken('demo@sunauth.test'); // send this token to the user by email
    if ($token !== false) {
        echo 'Reset token: '.$token.'<br>';
        if ($auth->verifyResetToken($token) !== false) {   // token valid and not expired
            $auth->resetPassword($token, 'demo1234');      // sets the new password, clears all sessions
            echo 'Password has been reset.';
        }
    }
    */


    /*
    // Example for Change Password (verifies the old password first)
    if ($auth->changePassword(1, 'demo1234', 'demo1234')) { // (userId, oldPassword, newPassword)
        echo 'Password changed.';
    } else {
        echo 'Change failed: '.$auth->lastError();
    }
    */


    /*
    // Example for Two Factor Authentication - Enable (requires "twofa_secret" column)
    $data = $auth->enableTwoFactor(1); // user id
    echo 'Secret: '.$data['secret'].'<br>'; // base32 secret
    echo 'OTP URI: '.$data['uri'];          // otpauth:// uri, render it as a QR code in an authenticator app
    */


    /*
    // Example for Two Factor Authentication - Verify a code
    if ($auth->verifyTwoFactorCode(1, '123456')) { // (userId, 6-digit code from the app)
        echo 'Code is valid.';
    } else {
        echo 'Code is invalid.';
    }
    */


    /*
    // Example for Two Factor Authentication - Login flow
    $auth->login('demo@sunauth.test', 'demo1234'); // when 2FA is enabled this opens a pending session
    if ($auth->pendingTwoFactor() !== false) {     // waiting for the 2FA code
        if ($auth->verifyTwoFactor('123456')) {    // promotes the pending session on success
            echo 'Fully logged in.';
        } else {
            echo 'Wrong 2FA code.';
        }
    } else {
        echo 'Logged in (2FA not enabled).';
    }
    */


    /*
    // Example for Two Factor Authentication - Disable
    $auth->disableTwoFactor(1); // user id
    echo '2FA disabled.';
    */


    /*
    // Example for Configuration (get/set a config value at runtime)
    echo 'Max attempts: '.$auth->config('maxAttempts').'<br>'; // get
    $auth->config('lockoutTime', 600);                          // set (10 minutes)
    echo 'New lockout time: '.$auth->config('lockoutTime');
    */


    /*
    // Example for Direct Database Access (the underlying SunDB instance)
    $db = $auth->db();
    $count = $db->tableCount('users');
    echo 'Total users: '.$count;
    */


    /*
    // Example for Static Instance (reach the last SunAuth instance from anywhere)
    $auth2 = SunAuth::getInstance();
    echo $auth2->isLoggedIn() ? 'Logged in.' : 'Not logged in.';
    */

?>
