import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grocery/blocs/addresses_bloc.dart';
import 'package:grocery/models/data_models/address.dart';
import 'package:grocery/models/state_models/checkout_model.dart';
import 'package:grocery/models/state_models/theme_model.dart';
import 'package:grocery/services/auth.dart';
import 'package:grocery/services/database.dart';
import 'package:grocery/ui/addresses/add_address.dart';
import 'package:grocery/widgets/cards.dart';
import 'package:grocery/widgets/fade_in.dart';
import 'package:grocery/widgets/texts.dart';
import 'package:provider/provider.dart';

class Addresses extends StatefulWidget {
  final AddressesBloc bloc;
  final EdgeInsets? padding;

  const Addresses({required this.bloc, this.padding});

  static Widget create(BuildContext context,
      {EdgeInsets? padding, String? selected}) {
    final auth = Provider.of<AuthBase>(context);
    final database = Provider.of<Database>(context);

    return Provider<AddressesBloc>(
      create: (context) =>
          AddressesBloc(uid: auth.uid, database: database, selected: selected),
      child: Consumer<AddressesBloc>(
        builder: (context, bloc, _) {
          return Addresses(
            bloc: bloc,
            padding: padding,
          );
        },
      ),
    );
  }

  static createWithScaffold(BuildContext context) {
    final auth = Provider.of<AuthBase>(context, listen: false);
    final database = Provider.of<Database>(context, listen: false);

    Navigator.push(context, CupertinoPageRoute(builder: (context) {
      return Provider<AddressesBloc>(
        create: (context) => AddressesBloc(uid: auth.uid, database: database),
        child: Consumer<AddressesBloc>(
          builder: (context, bloc, _) {
            final themeModel = Provider.of<ThemeModel>(context, listen: false);

            return Scaffold(
              appBar: AppBar(
                title: Texts.headline3("My addresses", themeModel.textColor),
                backgroundColor: themeModel.secondBackgroundColor,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: themeModel.textColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Addresses(bloc: bloc),
            );
          },
        ),
      );
    }));
  }

  @override
  _AddressesState createState() => _AddressesState();
}

class _AddressesState extends State<Addresses> {
  late Stream<List<Address>> addressesStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    addressesStream = widget.bloc.getAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
    double width = MediaQuery.of(context).size.width;
    return ListView(
      padding: widget.padding ?? EdgeInsets.all(20),
      children: [
        ///Add address button
        GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              color: themeModel.secondBackgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: themeModel.accentColor,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Texts.headline3('Add address', themeModel.accentColor),
                )
              ],
            ),
          ),
          onTap: () {
            AddAddress.create(context);
          },
        ),

        StreamBuilder<List<Address>>(
          stream: addressesStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              ///If there are addresses
              List<Address> addresses = snapshot.data!;

              //If Checkout Model in tree
              try {
                final checkoutModel =
                    Provider.of<CheckoutModel>(context, listen: false);

                if (addresses.length == 0) {
                  checkoutModel.address = null;
                } else {
                  checkoutModel.address = addresses
                      .where((element) => element.selected == true)
                      .single;
                }
              } catch (e) {
                print("CheckoutModel not in tree");
              }

              return Column(
                children: List.generate(addresses.length, (position) {
                  return FadeIn(
                    child: Cards.address(context, address: addresses[position]),
                  );
                }),
              );
            } else if (snapshot.hasError) {
              ///If there is an error
              return FadeIn(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: SvgPicture.asset(
                      'images/state_images/error.svg',
                      width: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            } else {
              ///If loading
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        )
      ],
    );
  }
}
