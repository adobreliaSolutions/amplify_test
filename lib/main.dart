import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_test/models/ModelProvider.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;

  String getMultiLineString(String userPoolId) {
    return ''' {
      "UserAgent": "aws-amplify-cli/2.0",
      "Version": "1.0",
          "api": {
        "plugins": {
            "awsAPIPlugin": {
                "amplifytest": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://hnfpwalmlngc5pfmmuxtoomosy.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "AWS_IAM"
                }
            }
        }
    },
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify-cli/0.1.0",
            "Version": "0.1.0",
            "IdentityManager": {
              "Default": {}
            },
           "AppSync": {
                    "Default": {
                        "ApiUrl": "https://hnfpwalmlngc5pfmmuxtoomosy.appsync-api.us-east-1.amazonaws.com/graphql",
                        "Region": "us-east-1",
                        "AuthMode": "AWS_IAM",
                        "ClientDatabasePrefix": "amplifytest_AWS_IAM"
                    }
                },
            "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "us-east-1:e4570f60-6680-4fe6-9d3f-74c5bce16d0d",
                            "Region": "us-east-1"
                        }
                    }
                },
            "CognitoUserPool": {
              "Default": {
                "PoolId": "us-east-1_aLcWWLExy",
                "AppClientId": "3ehfp5371mekqdeqq32d63nu4p",
                "Region": "us-east-1"
              }
            },
            "Auth": {
              "Default": {
                "authenticationFlowType": "USER_SRP_AUTH"
              }
            }
          }
        }
      }
    }
    ''';
  }

  @override
  void initState() {
    super.initState();
    configureAmplify();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void configureAmplify() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI(modelProvider: ModelProvider.instance);
    await Amplify.addPlugins([auth, api]);
    await Amplify.configure(getMultiLineString('"us-west-2_1tbomgWWN"'));
    try {
      setState(() {
        _amplifyConfigured = true;
      });
    } on Exception catch (e) {
      safePrint(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Amplify Core example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Is Amplify Configured?: $_amplifyConfigured\n'),
              OutlinedButton(onPressed: onPressed, child: Text("Login")),
              OutlinedButton(onPressed: createTodo, child: Text("Post entity")),
              OutlinedButton(onPressed: isUserSignedIn, child: Text("Is SignedIn?"))

            ],
          ),
        ),
      ),
    );
  }

  Future<SignInResult> confirmSignInNewPassword(String newPassword) async {
    return Amplify.Auth.confirmSignIn(
      confirmationValue: newPassword,
    );
  }

  Future<bool>? isUserSignedIn() async {
    final result = await Amplify.Auth.fetchAuthSession();
    return result.isSignedIn;
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(StringProperty('amplifyConfig', getMultiLineString('"us-west-2_1tbomgWWN"')));
  // }

  Future<void> onPressed() async {

    try {
      final result = await Amplify.Auth.signIn(
        username: 'mecibep409@meidecn.com',
        password: "rail70'ramps",
      );
      await _handleSignInResult(result);
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
    }
  }

  Future<void> createTodo() async {
    try {
      final todo = Todo(name: 'my first todo', description: 'todo description');
      final request = ModelMutations.create(todo);
      final response = await Amplify.API.mutate(request: request).response;

      final createdTodo = response.data;
      if (createdTodo == null) {
        safePrint('errors: ${response.errors}');
        return;
      }
      safePrint('Mutation result: ${createdTodo.name}');
    } on ApiException catch (e) {
      safePrint('Mutation failed: $e');
    }
  }

  Future<void> _handleSignInResult(SignInResult result) async {
    switch (result.nextStep.signInStep) {
      case AuthSignInStep.confirmSignInWithSmsMfaCode:
        final codeDeliveryDetails = result.nextStep.codeDeliveryDetails!;
        _handleCodeDelivery(codeDeliveryDetails);
        break;
      case AuthSignInStep.confirmSignInWithNewPassword:
        final res = await confirmSignInNewPassword("rail70'ramps");
        safePrint('Enter a new password to continue signing in');
        break;
      case AuthSignInStep.confirmSignInWithCustomChallenge:
        final parameters = result.nextStep.additionalInfo;
        final prompt = parameters['prompt']!;
        safePrint(prompt);
        break;
      case AuthSignInStep.resetPassword:
        print("resetPassword");
        break;
      case AuthSignInStep.confirmSignUp:
      // Resend the sign up code to the registered device.
        print("confirmSignUp");
        break;
      case AuthSignInStep.done:
        safePrint('Sign in is complete');
        break;
    }
  }

  void _handleCodeDelivery(AuthCodeDeliveryDetails codeDeliveryDetails) {
    safePrint(
      'A confirmation code has been sent to ${codeDeliveryDetails.destination}. '
          'Please check your ${codeDeliveryDetails.deliveryMedium.name} for the code.',
    );
  }
}
