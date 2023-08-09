import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'env.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late TextEditingController paymentController;
  late GlobalKey<FormState> paymentForm;
  Map<String, dynamic>? paymentIntentData;

  @override
  void initState() {
    super.initState();
    paymentController = TextEditingController();
    paymentForm = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment Example'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: paymentForm,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: paymentController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Required field';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter an amout',
                  fillColor: const Color(0xffF5F5F5),
                  filled: true,
                  border: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xff1D275C),
                      width: 2.01,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xffCCCCCC),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xffD6001A),
                      width: 2.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xffF0642F),
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (paymentForm.currentState!.validate()) {
                    debugPrint(paymentController.text);
                    var paymentamount = int.parse(paymentController.text) * 100;

                    makePayment(
                        amount: paymentamount.toString(), currency: "USD");
                  }
                },
                child: const Text('Make Payment'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> makePayment(
      {required String amount, required String currency}) async {
    debugPrint(amount);
    try {
      paymentIntentData = await createPaymentIntent(amount, currency);

      const gpay = PaymentSheetGooglePay(
        merchantCountryCode: "US",
        currencyCode: "USD",
        testEnv: true,
      );
      if (paymentIntentData != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            googlePay: gpay,
            merchantDisplayName: 'Adiwele',
            paymentIntentClientSecret: paymentIntentData!['client_secret'],
            customerEphemeralKeySecret: paymentIntentData!['ephemeralKey'],
          ),
        );
        displayPaymentSheet();
      }
    } catch (e, s) {
      debugPrint('exception:$e$s');
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then(
            (value) {},
          );
    } on StripeException catch (e) {
      debugPrint('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );

      return jsonDecode(response.body.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
