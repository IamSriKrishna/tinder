import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tinder_clone_app/common/color_constants.dart';
import 'package:flutter_tinder_clone_app/data/explore_json.dart';
import 'package:flutter_tinder_clone_app/data/icons.dart';
import 'package:swipe_cards/draggable_card.dart';
import 'package:swipe_cards/swipe_cards.dart';

/// Enhanced ExploreScreen with professional architecture and awesome features
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Core data management
  List<Map<String, dynamic>> _profiles = [];
  late MatchEngine _matchEngine;
  
  // Animation controllers for smooth interactions
  late AnimationController _likeAnimationController;
  late AnimationController _nopeAnimationController;
  late AnimationController _superLikeAnimationController;
  late AnimationController _cardShakeController;
  late AnimationController _buttonPressController;
  
  // Animations
  late Animation<double> _likeAnimation;
  late Animation<double> _nopeAnimation;
  late Animation<double> _superLikeAnimation;
  late Animation<double> _cardShakeAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  // User interaction tracking with enhanced analytics
  final List<Map<String, dynamic>> _likedProfiles = [];
  final List<Map<String, dynamic>> _dislikedProfiles = [];
  final List<Map<String, dynamic>> _superLikedProfiles = [];
  final Map<String, DateTime> _interactionTimestamps = {};
  
  // UI state management
  bool _showLikeIcon = false;
  bool _showNopeIcon = false;
  bool _showSuperLikeIcon = false;
  bool _isLoading = false;
  int _currentCardIndex = 0;
  
  // Performance optimization
  static const int _preloadCount = 3;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeProfiles();
    _initializeAnimations();
    _initializeSwipeCards();
  }

  /// Initialize profiles with error handling and data validation
  void _initializeProfiles() {
    try {
      _profiles = List<Map<String, dynamic>>.from(explore_json)
          .where((profile) => _validateProfile(profile))
          .toList();
      
      if (_profiles.isEmpty) {
        _handleEmptyProfiles();
      }
    } catch (e) {
      _handleProfileLoadError(e);
    }
  }

  /// Validate profile data integrity
  bool _validateProfile(Map<String, dynamic> profile) {
    return profile.containsKey('name') &&
           profile.containsKey('age') &&
           profile.containsKey('img') &&
           profile['name']?.toString().trim().isNotEmpty == true;
  }

  /// Initialize all animation controllers with optimized curves
  void _initializeAnimations() {
    const animationDuration = Duration(milliseconds: 600);
    
    _likeAnimationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _nopeAnimationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _superLikeAnimationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _cardShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonPressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Create smooth, elastic animations
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _nopeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nopeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _superLikeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _superLikeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _cardShakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _cardShakeController,
        curve: Curves.elasticInOut,
      ),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonPressController,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Initialize swipe cards with enhanced error handling
  void _initializeSwipeCards() {
    if (_profiles.isEmpty) return;
    
    try {
      final swipeItems = _profiles.asMap().entries.map((entry) {
        final index = entry.key;
        final profile = entry.value;
        
        return SwipeItem(
          content: profile,
          likeAction: () => _handleLike(profile, index),
          nopeAction: () => _handleNope(profile, index),
          superlikeAction: () => _handleSuperLike(profile, index),
          onSlideUpdate: _handleSlideUpdate,
        );
      }).toList();

      _matchEngine = MatchEngine(swipeItems: swipeItems);
    } catch (e) {
      _handleSwipeInitError(e);
    }
  }

  /// Enhanced like handler with analytics and feedback
  Future<void> _handleLike(Map<String, dynamic> person, int index) async {
    await _recordInteraction(person, 'like');
    
    if (!mounted) return;
    
    setState(() {
      _likedProfiles.add(person);
      _showLikeIcon = true;
      _currentCardIndex = index + 1;
    });
    
    await _playHapticFeedback();
    await _animateAndReset(_likeAnimationController, () {
      if (mounted) {
        setState(() => _showLikeIcon = false);
      }
    });

    await _checkForMatch(person);
    _logInteraction("❤️ Liked ${person['name']}");
  }

  /// Enhanced nope handler with smooth animations
  Future<void> _handleNope(Map<String, dynamic> person, int index) async {
    await _recordInteraction(person, 'nope');
    
    if (!mounted) return;
    
    setState(() {
      _dislikedProfiles.add(person);
      _showNopeIcon = true;
      _currentCardIndex = index + 1;
    });
    
    await _playHapticFeedback();
    await _animateAndReset(_nopeAnimationController, () {
      if (mounted) {
        setState(() => _showNopeIcon = false);
      }
    });

    _logInteraction("❌ Passed on ${person['name']}");
  }

  /// Enhanced super like handler with special effects
  Future<void> _handleSuperLike(Map<String, dynamic> person, int index) async {
    await _recordInteraction(person, 'superlike');
    
    if (!mounted) return;
    
    setState(() {
      _superLikedProfiles.add(person);
      _showSuperLikeIcon = true;
      _currentCardIndex = index + 1;
    });
    
    await _playHapticFeedback(HapticFeedback.heavyImpact);
    await _animateAndReset(_superLikeAnimationController, () {
      if (mounted) {
        setState(() => _showSuperLikeIcon = false);
      }
    });

    await _showSuperLikeDialog(person);
    _logInteraction("⭐ Super Liked ${person['name']}");
  }

  /// Record interaction with timestamp for analytics
  Future<void> _recordInteraction(Map<String, dynamic> person, String action) async {
    _interactionTimestamps['${person['name']}_$action'] = DateTime.now();
    // TODO: Send analytics to backend
  }

  /// Play haptic feedback based on interaction type
  Future<void> _playHapticFeedback([Function? feedback]) async {
    try {
      if (feedback != null) {
        await feedback();
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Silently handle haptic feedback errors
      debugPrint('Haptic feedback error: $e');
    }
  }

  /// Generic animation helper with cleanup
  Future<void> _animateAndReset(AnimationController controller, VoidCallback onComplete) async {
    try {
      await controller.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      controller.reset();
      onComplete();
    } catch (e) {
      debugPrint('Animation error: $e');
      onComplete();
    }
  }

  /// Enhanced slide update handler with improved responsiveness
  Future<void> _handleSlideUpdate(SlideRegion? region) async {
    if (!mounted) return;
    
    setState(() {
      _showLikeIcon = region == SlideRegion.inLikeRegion;
      _showNopeIcon = region == SlideRegion.inNopeRegion;
      _showSuperLikeIcon = region == SlideRegion.inSuperLikeRegion;
    });
  }

  /// Smart match detection with improved algorithm
  Future<void> _checkForMatch(Map<String, dynamic> person) async {
    // Enhanced match algorithm - consider user preferences, activity, etc.
    final matchProbability = _calculateMatchProbability(person);
    final random = DateTime.now().millisecond % 100;
    
    if (random < matchProbability) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showMatchDialog(person);
      }
    }
  }

  /// Calculate match probability based on user behavior and profile data
  int _calculateMatchProbability(Map<String, dynamic> person) {
    int baseProbability = 25; // Base 25% chance
    
    // Increase probability for profiles with more complete information
    if (person.containsKey('bio') && person['bio'].toString().length > 50) {
      baseProbability += 10;
    }
    
    if (person.containsKey('interests') && (person['interests'] as List).length > 3) {
      baseProbability += 5;
    }
    
    // Consider user's interaction history
    if (_likedProfiles.length > _dislikedProfiles.length) {
      baseProbability += 10;
    }
    
    return baseProbability.clamp(0, 80);
  }

  /// Enhanced match dialog with stunning animations
  Future<void> _showMatchDialog(Map<String, dynamic> person) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _MatchDialog(person: person, onStartChat: _startChat),
    );
  }

  /// Enhanced super like dialog
  Future<void> _showSuperLikeDialog(Map<String, dynamic> person) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _SuperLikeDialog(person: person),
    );
  }

  /// Start chat with enhanced navigation
  void _startChat(Map<String, dynamic> person) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble, color: Colors.white),
            const SizedBox(width: 10),
            Text("Starting chat with ${person['name']}..."),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Enhanced bottom sheet action handler with animations
  Future<void> _handleBottomSheetAction(int index) async {
    if (_matchEngine.currentItem == null) {
      await _shakeCard();
      return;
    }

    await _animateButtonPress();
    
    switch (index) {
      case 0: // Rewind
        await _rewindLastAction();
        break;
      case 1: // Nope
        _matchEngine.currentItem?.nope();
        break;
      case 2: // Super Like
        _matchEngine.currentItem?.superLike();
        break;
      case 3: // Like
        _matchEngine.currentItem?.like();
        break;
      case 4: // Boost
        await _showBoostDialog();
        break;
    }
  }

  /// Animate button press for better UX
  Future<void> _animateButtonPress() async {
    await _buttonPressController.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    _buttonPressController.reverse();
  }

  /// Shake card animation for invalid actions
  Future<void> _shakeCard() async {
    for (int i = 0; i < 3; i++) {
      await _cardShakeController.forward();
      await _cardShakeController.reverse();
    }
  }

  /// Enhanced rewind functionality
  Future<void> _rewindLastAction() async {
    // TODO: Implement actual rewind logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.undo, color: Colors.white),
            SizedBox(width: 10),
            Text("Rewind feature - Premium only"),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'UPGRADE',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to premium screen
          },
        ),
      ),
    );
  }

  /// Enhanced boost dialog
  Future<void> _showBoostDialog() async {
    return showDialog(
      context: context,
      builder: (context) => _BoostDialog(),
    );
  }

  /// Reload profiles with loading state
  Future<void> _reloadProfiles() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate API call
      
      setState(() {
        _profiles = List.from(explore_json);
        _currentCardIndex = 0;
      });
      
      _initializeSwipeCards();
    } catch (e) {
      _handleProfileLoadError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Error handlers
  void _handleEmptyProfiles() {
    debugPrint('No valid profiles found');
  }

  void _handleProfileLoadError(Object error) {
    debugPrint('Profile load error: $error');
    // TODO: Show error dialog or retry mechanism
  }

  void _handleSwipeInitError(Object error) {
    debugPrint('Swipe initialization error: $error');
    // TODO: Implement fallback UI
  }

  void _logInteraction(String message) {
    debugPrint(message);
    // TODO: Send to analytics service
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ColorConstants.kWhite,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomSheet: _buildBottomSheet(),
    );
  }

  /// Build enhanced app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.person_outline, color: Colors.grey.shade600),
        onPressed: () => debugPrint("Profile tapped"),
        tooltip: 'Profile',
      ),
      title: Hero(
        tag: 'app_logo',
        child: Image.network(
          'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Flogowik.com%2Fcontent%2Fuploads%2Fimages%2Ftinder4318.jpg&f=1&nofb=1&ipt=d5cc0910a011f8b3df3e3306f67e32c32abba49cf06a54bd09d93f70f512c46c',
          height: 100,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const CircularProgressIndicator();
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text('Tinder', style: TextStyle(color: Colors.pink));
          },
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade600),
          onPressed: () => debugPrint("Chat tapped"),
          tooltip: 'Messages',
        ),
      ],
    );
  }

  /// Build main body with enhanced error handling
  Widget _buildBody() {
    if (_isLoading) {
      return const _LoadingWidget();
    }

    if (_profiles.isEmpty) {
      return _EmptyProfilesWidget(onReload: _reloadProfiles);
    }

    return _SwipeableCardsWidget(
      profiles: _profiles,
      matchEngine: _matchEngine,
      currentIndex: _currentCardIndex,
      showLikeIcon: _showLikeIcon,
      showNopeIcon: _showNopeIcon,
      showSuperLikeIcon: _showSuperLikeIcon,
      likeAnimation: _likeAnimation,
      nopeAnimation: _nopeAnimation,
      superLikeAnimation: _superLikeAnimation,
      cardShakeAnimation: _cardShakeAnimation,
      onStackFinished: () {
        setState(() => _profiles.clear());
      },
      onShowPersonDetails: _showPersonDetails,
    );
  }

  /// Build enhanced bottom sheet
  Widget _buildBottomSheet() {
    return _ActionButtonsWidget(
      buttonScaleAnimation: _buttonScaleAnimation,
      onActionTap: _handleBottomSheetAction,
    );
  }

  /// Show person details in bottom sheet
  void _showPersonDetails(Map<String, dynamic> person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonDetailsSheet(person: person),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _nopeAnimationController.dispose();
    _superLikeAnimationController.dispose();
    _cardShakeController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }
}

// Separate widgets for better organization and reusability

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
          const SizedBox(height: 20),
          Text(
            "Finding amazing people near you...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfilesWidget extends StatelessWidget {
  final VoidCallback onReload;
  
  const _EmptyProfilesWidget({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.favorite_border,
                  size: 100,
                  color: Colors.grey.shade400,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            "No more people nearby!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Try expanding your search criteria",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text("RELOAD PROFILES"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableCardsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final MatchEngine matchEngine;
  final int currentIndex;
  final bool showLikeIcon;
  final bool showNopeIcon;
  final bool showSuperLikeIcon;
  final Animation<double> likeAnimation;
  final Animation<double> nopeAnimation;
  final Animation<double> superLikeAnimation;
  final Animation<double> cardShakeAnimation;
  final VoidCallback onStackFinished;
  final Function(Map<String, dynamic>) onShowPersonDetails;

  const _SwipeableCardsWidget({
    required this.profiles,
    required this.matchEngine,
    required this.currentIndex,
    required this.showLikeIcon,
    required this.showNopeIcon,
    required this.showSuperLikeIcon,
    required this.likeAnimation,
    required this.nopeAnimation,
    required this.superLikeAnimation,
    required this.cardShakeAnimation,
    required this.onStackFinished,
    required this.onShowPersonDetails,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 120, left: 10, right: 10, top: 10),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: cardShakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(cardShakeAnimation.value, 0),
                child: SizedBox(
                  height: size.height,
                  child: SwipeCards(
                    matchEngine: matchEngine,
                    itemBuilder: (context, index) {
                      if (index >= profiles.length) return Container();
                      return _PersonCard(
                        person: profiles[index],
                        size: size,
                        onShowDetails: onShowPersonDetails,
                      );
                    },
                    onStackFinished: onStackFinished,
                    upSwipeAllowed: true,
                    fillSpace: true,
                  ),
                ),
              );
            },
          ),
          
          // Animated overlay indicators
          if (showLikeIcon) _buildOverlayIcon(
            animation: likeAnimation,
            icon: Icons.favorite,
            color: Colors.green,
            position: const Alignment(0.8, -0.3),
          ),
          
          if (showNopeIcon) _buildOverlayIcon(
            animation: nopeAnimation,
            icon: Icons.close,
            color: Colors.red,
            position: const Alignment(-0.8, -0.3),
          ),
          
          if (showSuperLikeIcon) _buildOverlayIcon(
            animation: superLikeAnimation,
            icon: Icons.star,
            color: Colors.blue,
            position: const Alignment(0, -0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayIcon({
    required Animation<double> animation,
    required IconData icon,
    required Color color,
    required Alignment position,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: position,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: animation.value,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final Size size;
  final Function(Map<String, dynamic>) onShowDetails;

  const _PersonCard({
    required this.person,
    required this.size,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Background image with error handling
            Image.asset(
              person['img'],
              width: size.width,
              height: size.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size.width,
                  height: size.height,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            
            // Enhanced gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            
            // Person information
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${person['name']}, ${person['age']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  if (person.containsKey('job')) ...[
                    const SizedBox(height: 5),
                    Text(
                      person['job'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (person.containsKey('distance')) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${person['distance']} km away",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Info button with ripple effect
            Positioned(
              bottom: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => onShowDetails(person),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
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

class _ActionButtonsWidget extends StatelessWidget {
  final Animation<double> buttonScaleAnimation;
  final Function(int) onActionTap;

  const _ActionButtonsWidget({
    required this.buttonScaleAnimation,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      width: size.width,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(item_icons.length, (index) {
            return AnimatedBuilder(
              animation: buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: buttonScaleAnimation.value,
                  child: _ActionButton(
                    iconData: item_icons[index],
                    onTap: () => onActionTap(index),
                    color: _getIconColor(index),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Color? _getIconColor(int index) {
    switch (index) {
      case 0: return Colors.orange;
      case 1: return Colors.red;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _ActionButton extends StatefulWidget {
  final Map<String, dynamic> iconData;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.iconData,
    required this.onTap,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              width: widget.iconData['size'].toDouble(),
              height: widget.iconData['size'].toDouble(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.iconData['icon'],
                  width: widget.iconData['icon_size'].toDouble(),
                  color: widget.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
}

class _MatchDialog extends StatefulWidget {
  final Map<String, dynamic> person;
  final Function(Map<String, dynamic>) onStartChat;

  const _MatchDialog({
    required this.person,
    required this.onStartChat,
  });

  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _heartAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticInOut),
    );

    _scaleController.forward();
    _heartController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade400,
                    Colors.orange.shade400,
                    Colors.red.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "IT'S A MATCH! 🎉",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAvatar(widget.person['img']),
                      AnimatedBuilder(
                        animation: _heartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _heartAnimation.value,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                      _buildAvatar(null), // Current user placeholder
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "You and ${widget.person['name']} liked each other!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "KEEP SWIPING",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onStartChat(widget.person);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "SAY HELLO",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? imagePath) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.grey),
                  );
                },
              )
            : Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }
}

class _SuperLikeDialog extends StatefulWidget {
  final Map<String, dynamic> person;

  const _SuperLikeDialog({required this.person});

  @override
  State<_SuperLikeDialog> createState() => _SuperLikeDialogState();
}

class _SuperLikeDialogState extends State<_SuperLikeDialog>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late Animation<double> _starRotation;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _starRotation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );
    _starController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _starRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _starRotation.value * 3.14159,
                  child: const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 80,
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            const Text(
              "SUPER LIKE SENT! ⭐",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "You super liked ${widget.person['name']}!\nThey'll be notified that you're really interested.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }
}

class _BoostDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.rocket_launch, color: Colors.purple),
          const SizedBox(width: 10),
          const Text("Boost Your Profile"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Be one of the top profiles in your area for 30 minutes!",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Get up to 10x more matches!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text("Profile boosted! 🚀"),
                  ],
                ),
                backgroundColor: Colors.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          icon: const Icon(Icons.bolt),
          label: const Text("BOOST NOW"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> person;

  const _PersonDetailsSheet({required this.person});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(25),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${person['name']}, ${person['age']}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (person.containsKey('distance'))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "${person['distance']} km away",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (person.containsKey('job')) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Text(
                            person['job'],
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (person.containsKey('bio')) ...[
                      const SizedBox(height: 25),
                      const Text(
                        "About",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        person['bio'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (person.containsKey('interests')) ...[
                      const SizedBox(height: 25),
                      const Text(
                        "Interests",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (person['interests'] as List).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.shade100,
                                  Colors.orange.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.pink.shade200,
                              ),
                            ),
                            child: Text(
                              interest.toString(),
                              style: TextStyle(
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}