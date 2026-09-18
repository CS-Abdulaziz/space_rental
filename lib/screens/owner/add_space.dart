import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile_model.dart';
import '../../models/verification_model.dart';
import '../../models/space_model.dart';

class AddSpacePage extends StatefulWidget {
  const AddSpacePage({super.key});

  @override
  State<AddSpacePage> createState() => _AddSpacePageState();
}

class _AddSpacePageState extends State<AddSpacePage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final addressController = TextEditingController();
  final sizeController = TextEditingController();
  final dailyPriceController = TextEditingController();
  final monthlyPriceController = TextEditingController();

  String selectedType = 'Basement';

  bool loadingVerification = true;
  bool saving = false;

  ProfileModel? profile;
  VerificationModel? verification;

  // =========================
  // SPACE IMAGES
  // =========================

  final ImagePicker imagePicker = ImagePicker();
  List<XFile> selectedImages = [];

  static const cream = Color(0xffFBF8F3);
  static const brown = Color(0xff765640);
  static const darkBrown = Color(0xff4B382A);
  static const fieldColor = Color(0xffF4EFE8);

  @override
  void initState() {
    super.initState();
    loadVerification();
  }

  Future<void> loadVerification() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loadingVerification = false);
      return;
    }

    try {
      // =========================
      // PROFILE MODEL
      // =========================

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // =========================
      // VERIFICATION MODEL
      // =========================

      final verificationData = await supabase
          .from('verification')
          .select()
          .eq('owner_id', user.id)
          .order(
            'submitted_at',
            ascending: false,
          )
          .limit(1);

      ProfileModel? profileModel;
      VerificationModel? verificationModel;

      if (profileData != null) {
        profileModel = ProfileModel.fromJson(
          Map<String, dynamic>.from(profileData),
        );
      }

      if (verificationData.isNotEmpty) {
        verificationModel =
            VerificationModel.fromJson(
          Map<String, dynamic>.from(
            verificationData.first,
          ),
        );
      }

      if (mounted) {
        setState(() {
          profile = profileModel;
          verification = verificationModel;
          loadingVerification = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Verification loading error: $e',
      );

      if (mounted) {
        setState(
          () => loadingVerification = false,
        );
      }
    }
  }

  bool get isVerified {
    final status =
        verification?.status.toLowerCase();

    return status == 'approved';
  }

  InputDecoration decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: darkBrown,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: decoration(hint),
          ),
        ],
      ),
    );
  }

  // =========================
  // PICK IMAGES
  // =========================

  Future<void> pickImages() async {
    try {
      final images =
          await imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      setState(() {
        selectedImages = images.take(5).toList();
      });

      if (images.length > 5 && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'You can upload up to 5 photos.',
            ),
            backgroundColor: brown,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Image picker error: $e',
      );
    }
  }

  // =========================
  // REMOVE IMAGE
  // =========================

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // =========================
  // UPLOAD IMAGES
  // =========================

  Future<void> uploadSpaceImages(
    String spaceId,
    String userId,
  ) async {
    for (int i = 0;
        i < selectedImages.length;
        i++) {
      final image = selectedImages[i];

      final bytes = await image.readAsBytes();

      final originalName = image.name;

      String extension = 'jpg';

      if (originalName.contains('.')) {
        extension =
            originalName.split('.').last;
      }

      final filePath =
          '$userId/${spaceId}_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

      await supabase.storage
          .from('space-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: false,
            ),
          );

      final imageUrl = supabase.storage
          .from('space-images')
          .getPublicUrl(filePath);

      await supabase
          .from('space_images')
          .insert({
        'space_id': spaceId,
        'image_url': imageUrl,
      });
    }
  }

  Future<void> saveSpace() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    if (!isVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Your owner verification must be approved first.',
          ),
          backgroundColor: brown,
        ),
      );
      return;
    }

    if (titleController.text.trim().isEmpty ||
        addressController.text
            .trim()
            .isEmpty ||
        sizeController.text.trim().isEmpty ||
        dailyPriceController.text
            .trim()
            .isEmpty ||
        monthlyPriceController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all space details.',
          ),
          backgroundColor: brown,
        ),
      );
      return;
    }

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one photo of your space.',
          ),
          backgroundColor: brown,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      // =========================
      // CREATE SPACE
      // =========================

      final spaceData = await supabase
          .from('spaces')
          .insert({
            'owner_id': user.id,
            'title':
                titleController.text.trim(),
            'type': selectedType,
            'description': '',
            'address':
                addressController.text.trim(),
            'latitude': 24.7136,
            'longitude': 46.6753,
            'size': double.tryParse(
                  sizeController.text.trim(),
                ) ??
                0,
            'daily_price': double.tryParse(
                  dailyPriceController.text
                      .trim(),
                ) ??
                0,
            'monthly_price': double.tryParse(
                  monthlyPriceController.text
                      .trim(),
                ) ??
                0,
            'availability': 'Available',
            'status': 'active',
            'verified': true,
          })
          .select()
          .single();

      // Convert Supabase response to SpaceModel
      final SpaceModel space =
          SpaceModel.fromJson(
        Map<String, dynamic>.from(
          spaceData,
        ),
      );

      debugPrint(
        'Space created: ${space.id}',
      );

      // =========================
      // UPLOAD SPACE IMAGES
      // =========================

      await uploadSpaceImages(
        space.id,
        user.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Space added successfully ✨',
          ),
          backgroundColor: brown,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'Add space error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text('Error adding space: $e'),
            backgroundColor:
                Colors.red.shade700,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    addressController.dispose();
    sizeController.dispose();
    dailyPriceController.dispose();
    monthlyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingVerification) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(
          child:
              CircularProgressIndicator(
            color: brown,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        iconTheme:
            const IconThemeData(
          color: darkBrown,
        ),
        title: const Text(
          'Add New Space',
          style: TextStyle(
            color: darkBrown,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          10,
          22,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'List your space',
              style: TextStyle(
                fontSize: 29,
                fontWeight:
                    FontWeight.bold,
                fontStyle:
                    FontStyle.italic,
                color: darkBrown,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Add the details of the space you want to rent.',
              style: TextStyle(
                color: Color(0xff806F61),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            // VERIFICATION CARD
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(17),
              decoration:
                  BoxDecoration(
                color: isVerified
                    ? const Color(
                        0xffEEE5DB,
                      )
                    : const Color(
                        0xffF1E2D8,
                      ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Icons
                            .verified_rounded
                        : Icons
                            .warning_amber_rounded,
                    color: brown,
                    size: 29,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          isVerified
                              ? 'Owner Verified'
                              : 'Verification Required',
                          style:
                              const TextStyle(
                            color:
                                darkBrown,
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          isVerified
                              ? '${verification?.fullName ?? profile?.fullName ?? ''} • ${verification?.ownershipType ?? ''}'
                              : 'Complete owner verification before adding a space.',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xff806F61,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            field(
              'Space Name',
              titleController,
              'Example: Modern Private Basement',
            ),

            // TYPE
            const Text(
              'Space Type',
              style: TextStyle(
                color: darkBrown,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
              ),
              decoration:
                  BoxDecoration(
                color: fieldColor,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child:
                  DropdownButtonHideUnderline(
                child:
                    DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Parking',
                      child:
                          Text('Parking'),
                    ),
                    DropdownMenuItem(
                      value: 'Storage',
                      child:
                          Text('Storage'),
                    ),
                    DropdownMenuItem(
                      value: 'Basement',
                      child:
                          Text('Basement'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child:
                          Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType =
                            value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // =========================
            // SPACE PHOTOS
            // =========================

            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 17,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Space Photos',
                        style: TextStyle(
                          color: darkBrown,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedImages.length}/5',
                        style: const TextStyle(
                          color:
                              Color(0xff806F61),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: selectedImages.length >= 5
                        ? null
                        : pickImages,
                    child: Container(
                      width: double.infinity,
                      height:
                          selectedImages.isEmpty
                              ? 155
                              : 180,
                      decoration:
                          BoxDecoration(
                        color: fieldColor,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color: brown
                              .withOpacity(.25),
                          width: 1.2,
                        ),
                      ),
                      child: selectedImages
                              .isEmpty
                          ? Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xffE9DED3,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      15,
                                    ),
                                  ),
                                  child:
                                      const Icon(
                                    Icons
                                        .add_photo_alternate_outlined,
                                    color:
                                        brown,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Text(
                                  'Add photos of your space',
                                  style:
                                      TextStyle(
                                    color:
                                        darkBrown,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                const Text(
                                  'Tap to choose photos from your gallery',
                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xff806F61,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets
                                      .all(10),
                              child: GridView.builder(
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    selectedImages.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing:
                                      8,
                                  mainAxisSpacing:
                                      8,
                                ),
                                itemBuilder:
                                    (context,
                                        index) {
                                  final image =
                                      selectedImages[
                                          index];

                                  return Stack(
                                    fit: StackFit
                                        .expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                        child:
                                            Image.network(
                                          image.path,
                                          fit: BoxFit
                                              .cover,
                                          errorBuilder:
                                              (context,
                                                  error,
                                                  stackTrace) {
                                            return Container(
                                              color:
                                                  const Color(
                                                0xffE9DED3,
                                              ),
                                              child:
                                                  const Icon(
                                                Icons
                                                    .image_outlined,
                                                color:
                                                    brown,
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child:
                                            GestureDetector(
                                          onTap: () =>
                                              removeImage(
                                            index,
                                          ),
                                          child:
                                              Container(
                                            height:
                                                25,
                                            width:
                                                25,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Colors.white,
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                            child:
                                                const Icon(
                                              Icons.close,
                                              size:
                                                  15,
                                              color:
                                                  darkBrown,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                  ),

                  if (selectedImages.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 7,
                      ),
                      child: Text(
                        'You can add up to 5 photos.',
                        style:
                            const TextStyle(
                          color:
                              Color(0xff806F61),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            field(
              'Address',
              addressController,
              'Example: Al Malqa, Riyadh',
            ),

            field(
              'Size (m²)',
              sizeController,
              'Example: 45',
              keyboardType:
                  TextInputType.number,
            ),

            field(
              'Daily Price (SAR)',
              dailyPriceController,
              'Example: 80',
              keyboardType:
                  TextInputType.number,
            ),

            field(
              'Monthly Price (SAR)',
              monthlyPriceController,
              'Example: 1600',
              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    saving ? null : saveSpace,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      const Color(
                    0xffB9A99B,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )
                    : const Text(
                        'Add Space',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}