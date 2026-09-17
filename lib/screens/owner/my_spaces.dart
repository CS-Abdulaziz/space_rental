import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/space_model.dart';
import 'add_space.dart';

class MySpacesPage extends StatefulWidget {
  const MySpacesPage({super.key});

  @override
  State<MySpacesPage> createState() => _MySpacesPageState();
}

class _MySpacesPageState extends State<MySpacesPage> {
  final supabase = Supabase.instance.client;

  List<SpaceModel> spaces = [];
  bool loading = true;

  static const cream = Color(0xffFBF8F3);
  static const brown = Color(0xff765640);
  static const darkBrown = Color(0xff4B382A);
  static const lightBrown = Color(0xffEEE5DB);

  @override
  void initState() {
    super.initState();
    loadSpaces();
  }

  Future<void> loadSpaces() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final result = await supabase
          .from('spaces')
          .select('*, space_images(image_url)')
          .eq('owner_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      final List<SpaceModel> loadedSpaces = [];

      for (final item in result) {
        final json =
            Map<String, dynamic>.from(item);

        loadedSpaces.add(
          SpaceModel.fromJson(json),
        );
      }

      if (mounted) {
        setState(() {
          spaces = loadedSpaces;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load spaces error: $e');

      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> openAddSpace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddSpacePage(),
      ),
    );

    if (result == true) {
      loadSpaces();
    }
  }

  String fallbackImage(String type) {
    switch (type.toLowerCase()) {
      case 'parking':
        return 'assets/images/parking.jpeg';
      case 'storage':
        return 'assets/images/storage.jpeg';
      case 'basement':
        return 'assets/images/basement.jpeg';
      default:
        return 'assets/images/other.jpeg';
    }
  }

  IconData typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'parking':
        return Icons.local_parking_rounded;
      case 'storage':
        return Icons.inventory_2_outlined;
      case 'basement':
        return Icons.home_work_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Future<void> deleteSpace(String id) async {
    try {
      await supabase
          .from('spaces')
          .delete()
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Space deleted successfully',
            ),
            backgroundColor: brown,
          ),
        );
      }

      loadSpaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: brown,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child:
                        RefreshIndicator(
                      color: brown,
                      onRefresh: loadSpaces,
                      child: ListView(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          20,
                          18,
                          20,
                          20,
                        ),
                        children: [
                          // HEADER
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration:
                                    BoxDecoration(
                                  color: brown,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    22,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .home_work_outlined,
                                  color:
                                      Colors.white,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(
                                  width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'My Spaces',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            30,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        fontStyle:
                                            FontStyle
                                                .italic,
                                        color:
                                            darkBrown,
                                      ),
                                    ),
                                    SizedBox(
                                        height: 4),
                                    Text(
                                      'Everything you currently have listed.',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            14,
                                        color:
                                            Color(
                                          0xff8A7A6C,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 25),

                          if (spaces.isEmpty)
                            Container(
                              padding:
                                  const EdgeInsets
                                      .all(30),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  25,
                                ),
                              ),
                              child:
                                  const Column(
                                children: [
                                  Icon(
                                    Icons
                                        .home_work_outlined,
                                    size: 55,
                                    color: brown,
                                  ),
                                  SizedBox(
                                      height: 15),
                                  Text(
                                    'No spaces yet',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          darkBrown,
                                    ),
                                  ),
                                  SizedBox(
                                      height: 6),
                                  Text(
                                    'Add your first space and start earning.',
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        TextStyle(
                                      color:
                                          Color(
                                        0xff8A7A6C,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // SPACE CARDS
                          ...spaces.map(
                            (space) {
                              final title =
                                  space.title
                                          .isNotEmpty
                                      ? space.title
                                      : 'Untitled Space';

                              final type =
                                  space.type
                                          .isNotEmpty
                                      ? space.type
                                      : 'Other';

                              final address =
                                  space.address
                                          .isNotEmpty
                                      ? space.address
                                      : 'Riyadh';

                              final price =
                                  space.dailyPrice ??
                                      0;

                              final status =
                                  space.status
                                          .isNotEmpty
                                      ? space.status
                                      : 'active';

                              String? imageUrl;

                              if (space
                                  .imageUrls
                                  .isNotEmpty) {
                                imageUrl =
                                    space.imageUrls
                                        .first;
                              }

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  bottom: 18,
                                ),
                                height: 185,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    28,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                              0.04),
                                      blurRadius:
                                          12,
                                      offset:
                                          const Offset(
                                        0,
                                        5,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius
                                              .only(
                                        topLeft:
                                            Radius.circular(
                                          28,
                                        ),
                                        bottomLeft:
                                            Radius.circular(
                                          28,
                                        ),
                                      ),
                                      child:
                                          SizedBox(
                                        width: 125,
                                        height:
                                            double
                                                .infinity,
                                        child: imageUrl !=
                                                    null &&
                                                imageUrl
                                                    .isNotEmpty
                                            ? Image
                                                .network(
                                                imageUrl,
                                                fit: BoxFit
                                                    .cover,
                                                errorBuilder:
                                                    (_, __, ___) {
                                                  return Image
                                                      .asset(
                                                    fallbackImage(
                                                        type),
                                                    fit: BoxFit
                                                        .cover,
                                                  );
                                                },
                                              )
                                            : Image
                                                .asset(
                                                fallbackImage(
                                                    type),
                                                fit: BoxFit
                                                    .cover,
                                              ),
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          16,
                                        ),
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      Text(
                                                    title,
                                                    maxLines:
                                                        1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          darkBrown,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .verified_rounded,
                                                  color:
                                                      brown,
                                                  size:
                                                      22,
                                                ),
                                              ],
                                            ),

                                            const SizedBox(
                                                height:
                                                    7),

                                            Row(
                                              children: [
                                                Text(
                                                  type,
                                                  style:
                                                      const TextStyle(
                                                    color:
                                                        brown,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width:
                                                        7),
                                                const Text(
                                                    '•'),
                                                const SizedBox(
                                                    width:
                                                        7),
                                                Icon(
                                                  typeIcon(
                                                      type),
                                                  size:
                                                      17,
                                                  color:
                                                      brown,
                                                ),
                                              ],
                                            ),

                                            const SizedBox(
                                                height:
                                                    8),

                                            Text(
                                              address,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Color(
                                                  0xff8A7A6C,
                                                ),
                                                fontSize:
                                                    13,
                                              ),
                                            ),

                                            const Spacer(),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                RichText(
                                                  text:
                                                      TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${price.toStringAsFixed(0)} SAR',
                                                        style:
                                                            const TextStyle(
                                                          color:
                                                              darkBrown,
                                                          fontSize:
                                                              18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text:
                                                            ' / day',
                                                        style:
                                                            TextStyle(
                                                          color:
                                                              Color(
                                                            0xff8A7A6C,
                                                          ),
                                                          fontSize:
                                                              13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal:
                                                        12,
                                                    vertical:
                                                        7,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color:
                                                        lightBrown,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child:
                                                      Text(
                                                    status,
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          darkBrown,
                                                      fontSize:
                                                          12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(
                              height: 5),

                          // ADD SPACE BUTTON
                          GestureDetector(
                            onTap:
                                openAddSpace,
                            child: Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: brown,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  25,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .add_rounded,
                                    color: Colors
                                        .white,
                                    size: 32,
                                  ),
                                  SizedBox(
                                      width: 15),
                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Add New Space',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize:
                                                20,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(
                                            height:
                                                4),
                                        Text(
                                          'List a new space and start earning',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white70,
                                            fontSize:
                                                13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    color:
                                        Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}