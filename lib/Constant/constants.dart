
/// ----------------------------------------------
/// 🌐 Global Base URLs
/// ----------------------------------------------

const bool isProduction = false; // 👉 false karo agar test/UAT chahiye

/// Base URLs
const String BASE_URL_PRODUCTION = "https://connect.skillsconnect.in/api/mobile/";
const String BASE_URL_UAT = "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/";

/// Final Base URL (auto select based on environment)
const String BASE_URL = isProduction ? BASE_URL_PRODUCTION : BASE_URL_UAT;
