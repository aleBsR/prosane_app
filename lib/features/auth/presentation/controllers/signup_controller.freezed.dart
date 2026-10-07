// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signup_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignupFormData {

 String get tipoDocumento; String get numeroDocumento; bool get aceptaPolitica; String get nombre; String get apellido; String get sexo; DateTime? get fechaNacimiento; String get lugarNacimiento; String get paisResidencia; String get email; String get confirmEmail; String get password; String get confirmPassword;
/// Create a copy of SignupFormData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignupFormDataCopyWith<SignupFormData> get copyWith => _$SignupFormDataCopyWithImpl<SignupFormData>(this as SignupFormData, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SignupFormData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignupFormData&&(identical(other.tipoDocumento, _this.tipoDocumento) || other.tipoDocumento == _this.tipoDocumento)&&(identical(other.numeroDocumento, _this.numeroDocumento) || other.numeroDocumento == _this.numeroDocumento)&&(identical(other.aceptaPolitica, _this.aceptaPolitica) || other.aceptaPolitica == _this.aceptaPolitica)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.apellido, _this.apellido) || other.apellido == _this.apellido)&&(identical(other.sexo, _this.sexo) || other.sexo == _this.sexo)&&(identical(other.fechaNacimiento, _this.fechaNacimiento) || other.fechaNacimiento == _this.fechaNacimiento)&&(identical(other.lugarNacimiento, _this.lugarNacimiento) || other.lugarNacimiento == _this.lugarNacimiento)&&(identical(other.paisResidencia, _this.paisResidencia) || other.paisResidencia == _this.paisResidencia)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.confirmEmail, _this.confirmEmail) || other.confirmEmail == _this.confirmEmail)&&(identical(other.password, _this.password) || other.password == _this.password)&&(identical(other.confirmPassword, _this.confirmPassword) || other.confirmPassword == _this.confirmPassword));
}


@override
int get hashCode {
  final _this = this as SignupFormData;
  return Object.hash(runtimeType,_this.tipoDocumento,_this.numeroDocumento,_this.aceptaPolitica,_this.nombre,_this.apellido,_this.sexo,_this.fechaNacimiento,_this.lugarNacimiento,_this.paisResidencia,_this.email,_this.confirmEmail,_this.password,_this.confirmPassword);
}

@override
String toString() {
  final _this = this as SignupFormData;
  return 'SignupFormData(tipoDocumento: ${_this.tipoDocumento}, numeroDocumento: ${_this.numeroDocumento}, aceptaPolitica: ${_this.aceptaPolitica}, nombre: ${_this.nombre}, apellido: ${_this.apellido}, sexo: ${_this.sexo}, fechaNacimiento: ${_this.fechaNacimiento}, lugarNacimiento: ${_this.lugarNacimiento}, paisResidencia: ${_this.paisResidencia}, email: ${_this.email}, confirmEmail: ${_this.confirmEmail}, password: ${_this.password}, confirmPassword: ${_this.confirmPassword})';
}


}

/// @nodoc
abstract mixin class $SignupFormDataCopyWith<$Res>  {
  factory $SignupFormDataCopyWith(SignupFormData value, $Res Function(SignupFormData) _then) = _$SignupFormDataCopyWithImpl;
@useResult
$Res call({
 String tipoDocumento, String numeroDocumento, bool aceptaPolitica, String nombre, String apellido, String sexo, DateTime? fechaNacimiento, String lugarNacimiento, String paisResidencia, String email, String confirmEmail, String password, String confirmPassword
});




}
/// @nodoc
class _$SignupFormDataCopyWithImpl<$Res>
    implements $SignupFormDataCopyWith<$Res> {
  _$SignupFormDataCopyWithImpl(this._self, this._then);

  final SignupFormData _self;
  final $Res Function(SignupFormData) _then;

/// Create a copy of SignupFormData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tipoDocumento = null,Object? numeroDocumento = null,Object? aceptaPolitica = null,Object? nombre = null,Object? apellido = null,Object? sexo = null,Object? fechaNacimiento = freezed,Object? lugarNacimiento = null,Object? paisResidencia = null,Object? email = null,Object? confirmEmail = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(SignupFormData(
tipoDocumento: null == tipoDocumento ? _self.tipoDocumento : tipoDocumento // ignore: cast_nullable_to_non_nullable
as String,numeroDocumento: null == numeroDocumento ? _self.numeroDocumento : numeroDocumento // ignore: cast_nullable_to_non_nullable
as String,aceptaPolitica: null == aceptaPolitica ? _self.aceptaPolitica : aceptaPolitica // ignore: cast_nullable_to_non_nullable
as bool,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,apellido: null == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String,sexo: null == sexo ? _self.sexo : sexo // ignore: cast_nullable_to_non_nullable
as String,fechaNacimiento: freezed == fechaNacimiento ? _self.fechaNacimiento : fechaNacimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,lugarNacimiento: null == lugarNacimiento ? _self.lugarNacimiento : lugarNacimiento // ignore: cast_nullable_to_non_nullable
as String,paisResidencia: null == paisResidencia ? _self.paisResidencia : paisResidencia // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,confirmEmail: null == confirmEmail ? _self.confirmEmail : confirmEmail // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SignupFormData].
extension SignupFormDataPatterns on SignupFormData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignupFormData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignupFormData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignupFormData value)  $default,){
final _that = this;
switch (_that) {
case _SignupFormData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignupFormData value)?  $default,){
final _that = this;
switch (_that) {
case _SignupFormData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tipoDocumento,  String numeroDocumento,  bool aceptaPolitica,  String nombre,  String apellido,  String sexo,  DateTime? fechaNacimiento,  String lugarNacimiento,  String paisResidencia,  String email,  String confirmEmail,  String password,  String confirmPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignupFormData() when $default != null:
return $default(_that.tipoDocumento,_that.numeroDocumento,_that.aceptaPolitica,_that.nombre,_that.apellido,_that.sexo,_that.fechaNacimiento,_that.lugarNacimiento,_that.paisResidencia,_that.email,_that.confirmEmail,_that.password,_that.confirmPassword);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tipoDocumento,  String numeroDocumento,  bool aceptaPolitica,  String nombre,  String apellido,  String sexo,  DateTime? fechaNacimiento,  String lugarNacimiento,  String paisResidencia,  String email,  String confirmEmail,  String password,  String confirmPassword)  $default,) {final _that = this;
switch (_that) {
case _SignupFormData():
return $default(_that.tipoDocumento,_that.numeroDocumento,_that.aceptaPolitica,_that.nombre,_that.apellido,_that.sexo,_that.fechaNacimiento,_that.lugarNacimiento,_that.paisResidencia,_that.email,_that.confirmEmail,_that.password,_that.confirmPassword);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tipoDocumento,  String numeroDocumento,  bool aceptaPolitica,  String nombre,  String apellido,  String sexo,  DateTime? fechaNacimiento,  String lugarNacimiento,  String paisResidencia,  String email,  String confirmEmail,  String password,  String confirmPassword)?  $default,) {final _that = this;
switch (_that) {
case _SignupFormData() when $default != null:
return $default(_that.tipoDocumento,_that.numeroDocumento,_that.aceptaPolitica,_that.nombre,_that.apellido,_that.sexo,_that.fechaNacimiento,_that.lugarNacimiento,_that.paisResidencia,_that.email,_that.confirmEmail,_that.password,_that.confirmPassword);case _:
  return null;

}
}

}

/// @nodoc


class _SignupFormData implements SignupFormData {
  const _SignupFormData({this.tipoDocumento = '', this.numeroDocumento = '', this.aceptaPolitica = false, this.nombre = '', this.apellido = '', this.sexo = '', this.fechaNacimiento, this.lugarNacimiento = '', this.paisResidencia = '', this.email = '', this.confirmEmail = '', this.password = '', this.confirmPassword = ''});
  

@override@JsonKey() final  String tipoDocumento;
@override@JsonKey() final  String numeroDocumento;
@override@JsonKey() final  bool aceptaPolitica;
@override@JsonKey() final  String nombre;
@override@JsonKey() final  String apellido;
@override@JsonKey() final  String sexo;
@override final  DateTime? fechaNacimiento;
@override@JsonKey() final  String lugarNacimiento;
@override@JsonKey() final  String paisResidencia;
@override@JsonKey() final  String email;
@override@JsonKey() final  String confirmEmail;
@override@JsonKey() final  String password;
@override@JsonKey() final  String confirmPassword;

/// Create a copy of SignupFormData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignupFormDataCopyWith<_SignupFormData> get copyWith => __$SignupFormDataCopyWithImpl<_SignupFormData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignupFormData&&(identical(other.tipoDocumento, tipoDocumento) || other.tipoDocumento == tipoDocumento)&&(identical(other.numeroDocumento, numeroDocumento) || other.numeroDocumento == numeroDocumento)&&(identical(other.aceptaPolitica, aceptaPolitica) || other.aceptaPolitica == aceptaPolitica)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.apellido, apellido) || other.apellido == apellido)&&(identical(other.sexo, sexo) || other.sexo == sexo)&&(identical(other.fechaNacimiento, fechaNacimiento) || other.fechaNacimiento == fechaNacimiento)&&(identical(other.lugarNacimiento, lugarNacimiento) || other.lugarNacimiento == lugarNacimiento)&&(identical(other.paisResidencia, paisResidencia) || other.paisResidencia == paisResidencia)&&(identical(other.email, email) || other.email == email)&&(identical(other.confirmEmail, confirmEmail) || other.confirmEmail == confirmEmail)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tipoDocumento,numeroDocumento,aceptaPolitica,nombre,apellido,sexo,fechaNacimiento,lugarNacimiento,paisResidencia,email,confirmEmail,password,confirmPassword);
}

@override
String toString() {
    return 'SignupFormData(tipoDocumento: $tipoDocumento, numeroDocumento: $numeroDocumento, aceptaPolitica: $aceptaPolitica, nombre: $nombre, apellido: $apellido, sexo: $sexo, fechaNacimiento: $fechaNacimiento, lugarNacimiento: $lugarNacimiento, paisResidencia: $paisResidencia, email: $email, confirmEmail: $confirmEmail, password: $password, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class _$SignupFormDataCopyWith<$Res> implements $SignupFormDataCopyWith<$Res> {
  factory _$SignupFormDataCopyWith(_SignupFormData value, $Res Function(_SignupFormData) _then) = __$SignupFormDataCopyWithImpl;
@override @useResult
$Res call({
 String tipoDocumento, String numeroDocumento, bool aceptaPolitica, String nombre, String apellido, String sexo, DateTime? fechaNacimiento, String lugarNacimiento, String paisResidencia, String email, String confirmEmail, String password, String confirmPassword
});




}
/// @nodoc
class __$SignupFormDataCopyWithImpl<$Res>
    implements _$SignupFormDataCopyWith<$Res> {
  __$SignupFormDataCopyWithImpl(this._self, this._then);

  final _SignupFormData _self;
  final $Res Function(_SignupFormData) _then;

/// Create a copy of SignupFormData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tipoDocumento = null,Object? numeroDocumento = null,Object? aceptaPolitica = null,Object? nombre = null,Object? apellido = null,Object? sexo = null,Object? fechaNacimiento = freezed,Object? lugarNacimiento = null,Object? paisResidencia = null,Object? email = null,Object? confirmEmail = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(_SignupFormData(
tipoDocumento: null == tipoDocumento ? _self.tipoDocumento : tipoDocumento // ignore: cast_nullable_to_non_nullable
as String,numeroDocumento: null == numeroDocumento ? _self.numeroDocumento : numeroDocumento // ignore: cast_nullable_to_non_nullable
as String,aceptaPolitica: null == aceptaPolitica ? _self.aceptaPolitica : aceptaPolitica // ignore: cast_nullable_to_non_nullable
as bool,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,apellido: null == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String,sexo: null == sexo ? _self.sexo : sexo // ignore: cast_nullable_to_non_nullable
as String,fechaNacimiento: freezed == fechaNacimiento ? _self.fechaNacimiento : fechaNacimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,lugarNacimiento: null == lugarNacimiento ? _self.lugarNacimiento : lugarNacimiento // ignore: cast_nullable_to_non_nullable
as String,paisResidencia: null == paisResidencia ? _self.paisResidencia : paisResidencia // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,confirmEmail: null == confirmEmail ? _self.confirmEmail : confirmEmail // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SignupState {

 SignupFormData get formData; int get currentStep; bool get isSubmitting; String? get error; bool get registrado;
/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignupStateCopyWith<SignupState> get copyWith => _$SignupStateCopyWithImpl<SignupState>(this as SignupState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SignupState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignupState&&(identical(other.formData, _this.formData) || other.formData == _this.formData)&&(identical(other.currentStep, _this.currentStep) || other.currentStep == _this.currentStep)&&(identical(other.isSubmitting, _this.isSubmitting) || other.isSubmitting == _this.isSubmitting)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.registrado, _this.registrado) || other.registrado == _this.registrado));
}


@override
int get hashCode {
  final _this = this as SignupState;
  return Object.hash(runtimeType,_this.formData,_this.currentStep,_this.isSubmitting,_this.error,_this.registrado);
}

@override
String toString() {
  final _this = this as SignupState;
  return 'SignupState(formData: ${_this.formData}, currentStep: ${_this.currentStep}, isSubmitting: ${_this.isSubmitting}, error: ${_this.error}, registrado: ${_this.registrado})';
}


}

/// @nodoc
abstract mixin class $SignupStateCopyWith<$Res>  {
  factory $SignupStateCopyWith(SignupState value, $Res Function(SignupState) _then) = _$SignupStateCopyWithImpl;
@useResult
$Res call({
 SignupFormData formData, int currentStep, bool isSubmitting, String? error, bool registrado
});


$SignupFormDataCopyWith<$Res> get formData;

}
/// @nodoc
class _$SignupStateCopyWithImpl<$Res>
    implements $SignupStateCopyWith<$Res> {
  _$SignupStateCopyWithImpl(this._self, this._then);

  final SignupState _self;
  final $Res Function(SignupState) _then;

/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? formData = null,Object? currentStep = null,Object? isSubmitting = null,Object? error = freezed,Object? registrado = null,}) {
  return _then(SignupState(
formData: null == formData ? _self.formData : formData // ignore: cast_nullable_to_non_nullable
as SignupFormData,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,registrado: null == registrado ? _self.registrado : registrado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SignupFormDataCopyWith<$Res> get formData {
  
  return $SignupFormDataCopyWith<$Res>(_self.formData, (value) {
    return _then(_self.copyWith(formData: value));
  });
}
}


/// Adds pattern-matching-related methods to [SignupState].
extension SignupStatePatterns on SignupState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignupState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignupState value)  $default,){
final _that = this;
switch (_that) {
case _SignupState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignupState value)?  $default,){
final _that = this;
switch (_that) {
case _SignupState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SignupFormData formData,  int currentStep,  bool isSubmitting,  String? error,  bool registrado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignupState() when $default != null:
return $default(_that.formData,_that.currentStep,_that.isSubmitting,_that.error,_that.registrado);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SignupFormData formData,  int currentStep,  bool isSubmitting,  String? error,  bool registrado)  $default,) {final _that = this;
switch (_that) {
case _SignupState():
return $default(_that.formData,_that.currentStep,_that.isSubmitting,_that.error,_that.registrado);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SignupFormData formData,  int currentStep,  bool isSubmitting,  String? error,  bool registrado)?  $default,) {final _that = this;
switch (_that) {
case _SignupState() when $default != null:
return $default(_that.formData,_that.currentStep,_that.isSubmitting,_that.error,_that.registrado);case _:
  return null;

}
}

}

/// @nodoc


class _SignupState implements SignupState {
  const _SignupState({this.formData = const SignupFormData(), this.currentStep = 0, this.isSubmitting = false, this.error, this.registrado = false});
  

@override@JsonKey() final  SignupFormData formData;
@override@JsonKey() final  int currentStep;
@override@JsonKey() final  bool isSubmitting;
@override final  String? error;
@override@JsonKey() final  bool registrado;

/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignupStateCopyWith<_SignupState> get copyWith => __$SignupStateCopyWithImpl<_SignupState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignupState&&(identical(other.formData, formData) || other.formData == formData)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error)&&(identical(other.registrado, registrado) || other.registrado == registrado));
}


@override
int get hashCode {
    return Object.hash(runtimeType,formData,currentStep,isSubmitting,error,registrado);
}

@override
String toString() {
    return 'SignupState(formData: $formData, currentStep: $currentStep, isSubmitting: $isSubmitting, error: $error, registrado: $registrado)';
}


}

/// @nodoc
abstract mixin class _$SignupStateCopyWith<$Res> implements $SignupStateCopyWith<$Res> {
  factory _$SignupStateCopyWith(_SignupState value, $Res Function(_SignupState) _then) = __$SignupStateCopyWithImpl;
@override @useResult
$Res call({
 SignupFormData formData, int currentStep, bool isSubmitting, String? error, bool registrado
});


@override $SignupFormDataCopyWith<$Res> get formData;

}
/// @nodoc
class __$SignupStateCopyWithImpl<$Res>
    implements _$SignupStateCopyWith<$Res> {
  __$SignupStateCopyWithImpl(this._self, this._then);

  final _SignupState _self;
  final $Res Function(_SignupState) _then;

/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formData = null,Object? currentStep = null,Object? isSubmitting = null,Object? error = freezed,Object? registrado = null,}) {
  return _then(_SignupState(
formData: null == formData ? _self.formData : formData // ignore: cast_nullable_to_non_nullable
as SignupFormData,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,registrado: null == registrado ? _self.registrado : registrado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SignupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SignupFormDataCopyWith<$Res> get formData {
  
  return $SignupFormDataCopyWith<$Res>(_self.formData, (value) {
    return _then(_self.copyWith(formData: value));
  });
}
}

// dart format on
