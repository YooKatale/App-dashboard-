import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OurServices extends StatelessWidget {
  const OurServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ),
      ),
      child: Column(children: [
        ServicesTile(
          iconLeft: const FaIcon(FontAwesomeIcons.solidCreditCard,
              size: 40, color: Color.fromRGBO(24, 95, 45, 1)),
          labelLeft: 'Register for 25% YooCard premium & Gold discount',
          iconRight: const FaIcon(
            FontAwesomeIcons.headset,
            size: 40,
            color: Color.fromRGBO(24, 95, 45, 1),
          ),
          labelRight: '24/7 service support',
        ),
        ServicesTile(
          iconLeft: const FaIcon(FontAwesomeIcons.truckRampBox,
              size: 40, color: Color.fromRGBO(24, 95, 45, 1)),
          labelLeft:
              'Delivery offer [21-30] (Register for 9 days free delivery)',
          iconRight: Image.asset(
            'assets/card-secure.webp',
            width: 50,
            height: 50,
          ),
          labelRight: 'Safe, instant & secured',
        ),
      ]),
    );
  }
}

// ignore: must_be_immutable
class ServicesTile extends StatelessWidget {
  ServicesTile({
    super.key,
    required this.labelLeft,
    required this.iconLeft,
    required this.labelRight,
    required this.iconRight,
  });

  Widget iconLeft;
  String labelLeft;
  Widget iconRight;
  String labelRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
        ),
        shrinkWrap: true,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconLeft,
              SizedBox(
                  width: 150,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      labelLeft,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconRight,
                SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        labelRight,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
