/// The `platform` of `POST /api/me/push-token`. The server rejects any other
/// value with `400 VALIDATION_ERROR`, so the set is closed here.
enum PushPlatform {
  ios('IOS'),
  android('ANDROID');

  const PushPlatform(this.wireName);

  final String wireName;
}
