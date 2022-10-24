/*

    Unless directly included by the init file, this file will not be loaded when
    autoloading the module root contents as it is missing a realm prefix.

    Without a realm prefix, the file is skipped as we cannot what realm the file is
    supposed to be sent to so as a precaution it is avoided entirely.

*/

print("This will never be executed by the autoload")