// Authentication request and response models based on OpenAPI specification

class AuthUser {
  final String email;
  final String firstName;
  final String lastName;

  AuthUser({
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String? gender;
  final String? address;
  final String? role;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    this.gender,
    this.address,
    this.role,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'mobile_number': mobileNumber,
    };

    if (gender != null) {
      json['gender'] = gender;
    }

    if (address != null) {
      json['address'] = address;
    }

    if (role != null) {
      json['role'] = role;
    }

    return json;
  }
}

class GoogleLoginRequest {
  final String idToken;

  GoogleLoginRequest({
    required this.idToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_token': idToken,
    };
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}

class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? gender;
  final String? address;

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.gender,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (firstName != null) {
      json['first_name'] = firstName;
    }

    if (lastName != null) {
      json['last_name'] = lastName;
    }

    if (mobileNumber != null) {
      json['mobile_number'] = mobileNumber;
    }

    if (gender != null) {
      json['gender'] = gender;
    }

    if (address != null) {
      json['address'] = address;
    }

    return json;
  }
}

class TokenRefresh {
  final String? access;
  final String? refresh;

  TokenRefresh({
    this.access,
    this.refresh,
  });

  factory TokenRefresh.fromJson(Map<String, dynamic> json) {
    return TokenRefresh(
      access: json['access'] as String?,
      refresh: json['refresh'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (access != null) {
      json['access'] = access;
    }

    if (refresh != null) {
      json['refresh'] = refresh;
    }

    return json;
  }
}

class AuthSuccessResponse {
  final String token;
  final String refreshToken;
  final AuthUser user;

  AuthSuccessResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSuccessResponse.fromJson(Map<String, dynamic> json) {
    return AuthSuccessResponse(
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }
}

class MessageResponse {
  final String message;

  MessageResponse({
    required this.message,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}
