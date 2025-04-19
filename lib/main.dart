import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:onlyveyou/blocs/auth/auth_bloc.dart';
import 'package:onlyveyou/blocs/category/category_product_bloc.dart';
import 'package:onlyveyou/blocs/home/ai_recommend_bloc.dart';
import 'package:onlyveyou/blocs/home/home_bloc.dart';
import 'package:onlyveyou/blocs/inventory/inventory_bloc.dart';
import 'package:onlyveyou/blocs/map/store_map_bloc.dart';
import 'package:onlyveyou/blocs/mypage/email/email_bloc.dart';
import 'package:onlyveyou/blocs/mypage/nickname_edit/nickname_edit_bloc.dart';
import 'package:onlyveyou/blocs/mypage/order_status/order_status_bloc.dart';
import 'package:onlyveyou/blocs/mypage/password/password_bloc.dart';
import 'package:onlyveyou/blocs/mypage/phone_number/phone_number_bloc.dart';
import 'package:onlyveyou/blocs/mypage/profile_edit/profile_edit_bloc.dart';
import 'package:onlyveyou/blocs/mypage/set_new_password/set_new_password_bloc.dart';
import 'package:onlyveyou/blocs/order/order_bloc.dart';
import 'package:onlyveyou/blocs/payment/payment_bloc.dart';
import 'package:onlyveyou/blocs/product/cart/product_cart_bloc.dart';
import 'package:onlyveyou/blocs/product/like/product_like_bloc.dart';
import 'package:onlyveyou/blocs/product/productdetail_bloc.dart';
import 'package:onlyveyou/blocs/review/review_bloc.dart';
import 'package:onlyveyou/blocs/shutter/shutterpost_bloc.dart';
import 'package:onlyveyou/blocs/special_bloc/ai_onepick_bloc.dart';
import 'package:onlyveyou/blocs/special_bloc/weather/location_bloc.dart';
import 'package:onlyveyou/blocs/special_bloc/weather/weather_bloc.dart';
import 'package:onlyveyou/blocs/store/store_bloc.dart';
import 'package:onlyveyou/blocs/theme/theme_bloc.dart';
import 'package:onlyveyou/blocs/theme/theme_state.dart';
import 'package:onlyveyou/config/fcm.dart';
import 'package:onlyveyou/config/theme.dart';
import 'package:onlyveyou/cubit/category/category_cubit.dart';
import 'package:onlyveyou/repositories/auth_repository.dart';
import 'package:onlyveyou/repositories/category_repository.dart';
import 'package:onlyveyou/repositories/history_repository.dart';
import 'package:onlyveyou/repositories/home/ai_recommend_repository.dart';
import 'package:onlyveyou/repositories/home/home_repository.dart';
import 'package:onlyveyou/repositories/inventory/inventory_repository.dart';
import 'package:onlyveyou/repositories/map/goecoding_repository.dart';
import 'package:onlyveyou/repositories/mypage/profile_image_repository.dart';
import 'package:onlyveyou/repositories/order/order_repository.dart';
import 'package:onlyveyou/repositories/order/payment_repository.dart';
import 'package:onlyveyou/repositories/product/product_detail_repository.dart';
import 'package:onlyveyou/repositories/product_repository.dart';
import 'package:onlyveyou/repositories/review/review_repository.dart';
import 'package:onlyveyou/repositories/shopping_cart_repository.dart';
import 'package:onlyveyou/repositories/special/ai_onepick_repository.dart';
import 'package:onlyveyou/repositories/special/weather/location_repository.dart';
import 'package:onlyveyou/repositories/special/weather/weather_repository.dart';
import 'package:onlyveyou/screens/home/ai_recommend/ai_recommend_screen.dart';
import 'package:onlyveyou/screens/home/home/home_screen.dart';
import 'package:onlyveyou/screens/shopping_cart/shopping_cart_screen.dart';
import 'package:onlyveyou/utils/deeplink_service.dart';
import 'package:onlyveyou/utils/notification_util.dart';
import 'package:onlyveyou/utils/shared_preference_util.dart';

import 'blocs/history/history_bloc.dart';
import 'blocs/shopping_cart/shopping_cart_bloc.dart';
import 'core/router.dart';
import 'firebase_options.dart';
import 'repositories/search_repositories/suggestion_repository/suggestion_repository_impl.dart';
import 'screens/special/debate/chat/bloc/chat_bloc.dart';
import 'repositories/chat_repository.dart';
import 'screens/special/debate/vote/bloc/vote_bloc.dart';
import 'repositories/vote_repository.dart';

////
void main() async {
  // Flutter 바인딩 초기화 (반드시 필요)
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
      name: "onlyveyou", options: DefaultFirebaseOptions.currentPlatform);

  await NaverMapSdk.instance.initialize(
      clientId: 'n78adqcywr',
      onAuthFailed: (error) {
        print('Auth failed: $error');
      });

  //FCM Token 설정
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('fcmToken : $fcmToken');

  if (fcmToken != null) {
    OnlyYouSharedPreference().setToken(fcmToken);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmServerToken) {
    fcmToken ??= fcmServerToken;
    OnlyYouSharedPreference().setToken(fcmToken ?? "");
    print('fcmToken : $fcmToken');
  }).onError((err) {
    // Error getting token.
    print('error : Firebase token error');
  });

  // print("hash key ${await KakaoSdk.origin}");
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.fetchAndActivate();

  KakaoSdk.init(
    nativeAppKey: '0236522723df3e1aa869fe36e25e6297',
    javaScriptAppKey: 'Ye8ebc7de132c8c4f0b6881be99e20f5e',
  );
  final prefs = OnlyYouSharedPreference();
  await prefs.checkCurrentUser();
  print("hash key ${await KakaoSdk.origin}");

  DeepLinkService().initialize(router);

  //카카오톡
  kakaoSchemeStream.listen((url) {
    Uri uri = Uri.parse(url ?? "");
    final productId = uri.queryParameters['productId'];
    final screen = uri.queryParameters['screen'];
    print("productId : $productId, screen : $screen ");

    if (screen != null) {
      router.push(screen, extra: productId);
    }
  }, onError: (e) {
    // 에러 상황의 예외 처리 코드를 작성합니다.
    print("kakao listen error : $e");
  });

  // 위치 서비스 초기화 추가
  try {
    final locationRepository = LocationRepository();
    await locationRepository.checkLocationService();
  } catch (e) {
    debugPrint('Location service initialization error: $e');
  }

// 모든 제품 로컬 저장 (검색용)
  try {
    final productRepository = ProductRepository();
    await productRepository.fetchAndStoreAllProducts();
    final storedProducts = await productRepository.getStoredProducts();
    debugPrint('Stored products: ${storedProducts.length}');
  } catch (e) {
    debugPrint('Error fetching and storing products: $e');
  }

  // 모든 검색어 로컬 저장 (검색용)
  try {
    final suggestionRepository = SuggestionRepositoryImpl();
    await suggestionRepository.fetchAndStoreAllSuggestions();
    final storedSuggestions = await suggestionRepository.getStoredSuggestions();
    debugPrint('Stored suggestions: ${storedSuggestions.length}');
  } catch (e) {
    debugPrint('Error fetching and storing suggestions: $e');
  }

  //권한 설정, 버전관리
  await NotificationUtil().requestNotificationPermission();
  await NotificationUtil().initialize();

  //FCM 설정
  setupForegroundFirebaseMessaging();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
              create: (context) =>
                  OrderRepository(firestore: FirebaseFirestore.instance)),
          RepositoryProvider(create: (context) => PaymentRepository()), // 추가
          RepositoryProvider(
            create: (context) => ProfileImageRepository(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<WeatherBloc>(
                  create: (context) => WeatherBloc(
                    repository: WeatherRepository(),
                  ),
                ),
                BlocProvider<LocationBloc>(
                  create: (context) => LocationBloc(
                    repository: LocationRepository(),
                  ),
                ),
                RepositoryProvider(
                  create: (context) => AIOnepickRepository(),
                ),

// 등록된 Repository를 사용
                BlocProvider<AIOnepickBloc>(
                  create: (context) => AIOnepickBloc(
                    repository:
                        context.read<AIOnepickRepository>(), // 기존 인스턴스 재사용
                  ),
                ),
                BlocProvider(
                  create: (context) => AIRecommendBloc(
                    repository: AIRecommendRepository(),
                  ),
                  child: const AIRecommendScreen(),
                ),
                BlocProvider(
                  create: (context) => CartBloc(
                    cartRepository: ShoppingCartRepository(),
                  )..add(LoadCart()),
                  child: ShoppingCartScreen(),
                ),
                BlocProvider<AuthBloc>(
                  create: (context) => AuthBloc(
                      authRepository: AuthRepository(),
                      sharedPreference: OnlyYouSharedPreference()),
                ),
                BlocProvider(
                  create: (context) => HomeBloc(
                    homeRepository: HomeRepository(),
                    cartRepository: ShoppingCartRepository(),
                  )..add(LoadHomeData()),
                  child: const Home(), // HomeScreen 대신 Home을 사용
                ),
                BlocProvider(
                  create: (context) => HistoryBloc(
                    historyRepository: HistoryRepository(
                      cartRepository: ShoppingCartRepository(),
                    ),
                    cartRepository: ShoppingCartRepository(),
                  )..add(LoadHistoryItems()),
                ),
                BlocProvider<ProfileBloc>(
                  create: (context) => ProfileBloc(
                    ProfileImageRepository(), // ProfileImageRepository 인스턴스 주입 // FirebaseAuth 인스턴스 주입
                  ),
                  lazy: false, // Bloc을 화면 로드와 함께 미리 생성하여 상태를 유지
                ),

                BlocProvider<CategoryCubit>(
                    create: (context) =>
                        CategoryCubit(categoryRepository: CategoryRepository())
                          ..loadCategories()),
                BlocProvider<PasswordBloc>(
                  // PasswordBloc 추가
                  create: (context) => PasswordBloc(),
                ),
                BlocProvider<SetNewPasswordBloc>(
                  // PasswordBloc 추가
                  create: (context) => SetNewPasswordBloc(),
                ),
                BlocProvider<NicknameEditBloc>(
                  create: (context) => NicknameEditBloc(),
                ),
                BlocProvider<PhoneNumberBloc>(
                  create: (context) => PhoneNumberBloc(),
                ),
                BlocProvider<ThemeBloc>(
                  create: (context) => ThemeBloc(),
                ),
                BlocProvider<OrderStatusBloc>(
                  create: (context) => OrderStatusBloc(
                      OrderRepository(firestore: FirebaseFirestore.instance)),
                ),
                BlocProvider<ProductDetailBloc>(
                  create: (context) =>
                      ProductDetailBloc(ProductDetailRepository()),
                ),
                BlocProvider<PaymentBloc>(
                  create: (context) => PaymentBloc(
                    orderRepository: context.read<OrderRepository>(),
                    repository: PaymentRepository(),
                  ),
                ),
                BlocProvider<PostBloc>(
                  create: (context) => PostBloc(),
                ),
                BlocProvider<CategoryProductBloc>(
                  // CategoryProductBloc 추가
                  create: (context) => CategoryProductBloc(
                      repository: ProductDetailRepository()),
                ),
                BlocProvider<ProductCartBloc>(
                  // CategoryProductBloc 추가
                  create: (context) =>
                      ProductCartBloc(repository: ProductDetailRepository()),
                ),
                BlocProvider<ProductLikeBloc>(
                  // CategoryProductBloc 추가
                  create: (context) =>
                      ProductLikeBloc(repository: ProductDetailRepository()),
                ),
                BlocProvider<StoreBloc>(
                  create: (context) => StoreBloc(),
                ),
                BlocProvider<ReviewBloc>(
                  // CategoryProductBloc 추가
                  create: (context) =>
                      ReviewBloc(repository: ReviewRepository()),
                ),
                BlocProvider<OrderBloc>(
                  create: (context) => OrderBloc(
                      OrderRepository(firestore: FirebaseFirestore.instance)),
                ),
                BlocProvider<InventoryBloc>(
                  create: (context) => InventoryBloc(InventoryRepository()),
                ),
                BlocProvider<EmailBloc>(
                  create: (context) => EmailBloc(),
                ),
                BlocProvider<StoreMapBloc>(
                  create: (context) =>
                      StoreMapBloc(geocodingRepository: GeocodingRepository()),
                ),
                BlocProvider<ChatBloc>(
                  create: (context) => ChatBloc(
                    chatRepository: ChatRepository(),
                  ),
                ),
                BlocProvider<VoteBloc>(
                  create: (context) => VoteBloc(
                    voteRepository: VoteRepository(),
                  ),
                ),
              ],
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    themeMode: state.themeMode,
                    // themeMode: ThemeMode.light, //todo
                    theme: lightThemeData(),
                    darkTheme: darkThemeData(),
                    routerConfig: router,
                  );
                },
              ),
            );
          },
        ));
  }
}
