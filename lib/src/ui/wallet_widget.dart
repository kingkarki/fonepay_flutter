part of fonepay_flutter;

// Holds FonePay page's content widget
class FonePayPageContent {
  /// Page appbar
  final AppBar? appBar;

  /// Page custom loader
  final Widget? progressLoader;

  FonePayPageContent({this.appBar, this.progressLoader});
}

class FonePayPage extends StatefulWidget {
  /// The FonePayConfig configuration object.
  final FonePayConfig fonePayConfig;

  final FonePayPageContent? content;

  /// FonePayConfig page's content widget
  const FonePayPage(this.fonePayConfig, {this.content, Key? key})
      : super(key: key);

  @override
  State<FonePayPage> createState() => _FonePayPageState();
}

class _FonePayPageState extends State<FonePayPage> {
  late FonePayConfig fonePayConfig;

  /// Generate the URLRequest object from the FonePay configuration parameters.
  late URLRequest paymentRequest;

  /// FonePayPage page's content widget
  late final FonePayPageContent? content;

  @override
  void initState() {
    content = widget.content;
    fonePayConfig = widget.fonePayConfig;
    paymentRequest = getURLRequest();
    super.initState();
  }

  bool _isLoading = true;

  // InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
  //     crossPlatform: InAppWebViewOptions(
  //       useShouldOverrideUrlLoading: true,
  //       mediaPlaybackRequiresUserGesture: false,
  //     ),
  //     android: AndroidInAppWebViewOptions(
  //       useHybridComposition: true,
  //     ),
  //     ios: IOSInAppWebViewOptions(
  //       allowsInlineMediaPlayback: true,
  //     ));

  InAppWebViewSettings options = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    useShouldOverrideUrlLoading: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
  );

  // Generates the URLRequest object for the FonePay payment page.
  URLRequest getURLRequest() {
    var url =
        "${fonePayConfig.serverUrl}PID=${fonePayConfig.pid}&MD=${fonePayConfig.md}&AMT=${fonePayConfig.amt}&CRN=${fonePayConfig.crn}&DT=${fonePayConfig.dt}&R1=${fonePayConfig.r1}&R2=${fonePayConfig.r2}&DV=${fonePayConfig.dv}&RU=${fonePayConfig.ru}&PRN=${fonePayConfig.prn}";
    var urlRequest = URLRequest(url: WebUri(url));
    return urlRequest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: content?.appBar ??
          AppBar(
            backgroundColor: Colors.red,
            title: const Text("Pay Via FonePay"),
          ),
      body: Stack(
        children: [
          InAppWebView(
            // initialOptions: options,
            initialSettings: options,
            initialUrlRequest: paymentRequest,
            onWebViewCreated: (webViewController) {
              setState(() {
                _isLoading = false;
              });
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var url = navigationAction.request.url!;
              if (![
                "http",
                "https",
                "file",
                "chrome",
                "data",
                "javascript",
                "about"
              ].contains(url.scheme)) {
                return NavigationActionPolicy.CANCEL;
              }
              try {
                if ((url.toString()).contains(fonePayConfig.ru)) {
                  var result = Uri.parse(url.toString());
                  var body = result.queryParameters;
                  if (body['RC'] == 'successful') {
                    await createPaymentResponse(body).then((value) {
                      Navigator.pop(context, FonePayPaymentResult(data: value));
                    });
                  } else if (body['RC'] == 'failed') {
                    Navigator.pop(
                        context, FonePayPaymentResult(error: 'Payment Failed'));
                  }
                }
              } catch (e) {
                Navigator.pop(
                    context, FonePayPaymentResult(error: 'Payment Cancelled'));
              }

              return NavigationActionPolicy.ALLOW;
            },
            // onLoadError: (controller, url, code, message) {},
            onReceivedError: (controller, request, error) {},
            onConsoleMessage: (controller, consoleMessage) {},
          ),
          if (_isLoading)
            content?.progressLoader ??
                const Center(
                  child: CircularProgressIndicator(),
                ),
        ],
      ),
    );
  }

  Future<FonePayResponse> createPaymentResponse(
      Map<String, dynamic> body) async {
    final params = FonePayResponse(
        prn: body['PRN'],
        pid: body['PID'],
        ps: body['PS'],
        pAmt: body['P_AMT'],
        rAmt: body['R_AMT'],
        rc: body['RC'],
        bc: body['BC'],
        ini: body['INI'],
        uid: body['UID'],
        dv: body['DV']);
    return params;
  }
}
