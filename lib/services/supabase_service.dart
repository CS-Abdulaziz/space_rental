import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  User? get currentUser {
    return supabase.auth.currentUser;
  }

  String? get currentUserId {
    return supabase.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  Future<List<Map<String, dynamic>>> getSpaces() async {
    final data = await supabase.from('spaces').select();

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getOwnerSpaces() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final data = await supabase
        .from('spaces')
        .select()
        .eq('owner_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRenterBookings() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final data = await supabase
        .from('bookings')
        .select()
        .eq('renter_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getSavedSpaces() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    final data = await supabase
        .from('saved_spaces')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}