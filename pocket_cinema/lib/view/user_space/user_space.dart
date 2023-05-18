import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:pocket_cinema/controller/authentication.dart';
import 'package:pocket_cinema/controller/firestore_database.dart';
import 'package:pocket_cinema/controller/lists_provider.dart';
import 'package:pocket_cinema/controller/validate.dart';
import 'package:pocket_cinema/view/common_widgets/add_button.dart';
import 'package:pocket_cinema/view/common_widgets/comment_and_list_form.dart';
import 'package:pocket_cinema/view/common_widgets/personal_lists.dart';
import 'package:pocket_cinema/view/media_list/media_list.dart';
import 'package:pocket_cinema/view/user_space/widgets/list_button.dart';
import 'package:pocket_cinema/view/user_space/widgets/to_watch_list.dart';
import 'package:pocket_cinema/view/common_widgets/logo_title_app_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserSpacePage extends ConsumerStatefulWidget {
  const UserSpacePage({super.key});

  @override
  MyUserSpacePageState createState() => MyUserSpacePageState();
}

class MyUserSpacePageState extends ConsumerState<UserSpacePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _node = FocusNode();
  bool _isFormVisible = false;

  @override
  void initState() {
    super.initState();
    ref.refresh(toWatchListProvider).value;
    ref.read(watchListProvider.notifier).getWatchList();
  }

  void _handleSubmit(String listName) {
    if (!Validate.listName(listName)) {
      Fluttertoast.showToast(
          msg: "List name must be between 2 and 20 characters long");
      return;
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirestoreDatabase.createPersonalList(listName);
      Fluttertoast.showToast(msg: "Created a new list named '$listName'");
      ref.refresh(listsProvider).value;
      toggleCreateListFormVisibility();
    }
    _controller.clear();
    _node.unfocus();
  }

  void toggleCreateListFormVisibility() {
    setState(() {
      _isFormVisible = !_isFormVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const LogoTitleAppBar(
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        elevation: 0,
        actions: [
                IconButton(
                  key: const Key("logoutButton"),
                  icon: const HeroIcon(HeroIcons.arrowLeftOnRectangle,
                      style: HeroIconStyle.solid),
                  iconSize: 30,
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Authentication.signOut();
                    }
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/login');
                  },
                ),
              ],
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(listsProvider).value;
            ref.refresh(toWatchListProvider).value;
          },
          child: Stack(children: [
            ListView(
              children: <Widget>[
                const ToWatchList(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ListButton(
                          key: const Key("watchedListButton"),
                          icon: const HeroIcon(HeroIcons.checkCircle,
                              style: HeroIconStyle.solid),
                          labelText: "Watched",
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => MediaListPage(
                                  name: "Watched",
                                  mediaList: ref.watch(watchListProvider)),
                            ));
                          }),
                    ]),
                /*
              const SizedBox(width: 20),
              ListButton(
                icon: const HeroIcon(HeroIcons.ellipsisHorizontalCircle,
                    style: HeroIconStyle.solid),
                labelText: "Watching",
                onPressed: () {},
              ),*/

                const PersonalLists(),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
                visible: _isFormVisible,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CommentAndListForm(
                    key: const Key("createListField"),
                    controller: _controller,
                    focusNode: _node,
                    handleSubmit: _handleSubmit,
                    maxLines: 1,
                    onTapOutside: (_) {
                      toggleCreateListFormVisibility();
                      _node.unfocus();
                      _controller.clear();
                    },
                    prefixIcon: IconButton(
                      color: Colors.white,
                      icon: const HeroIcon(HeroIcons.xMark),
                      onPressed: () {
                        toggleCreateListFormVisibility();
                        _node.unfocus();
                        _controller.clear();
                      },
                    ),
                    suffixIcon: IconButton(
                      key: const Key("submitNewListButton"),
                      color: Colors.white,
                      icon: const HeroIcon(HeroIcons.plus),
                      onPressed: () {
                        _handleSubmit(_controller.text);
                      },
                    ),
                    hintText: "New list name",
                  ),
                ),
              ),
            )
          ])),
      floatingActionButton: Visibility(
          visible: !_isFormVisible,
          child: AddButton(
            key: const Key("addListButton"),
            onPressed: () => {
              toggleCreateListFormVisibility(),
              _node.requestFocus(),
            },
            buttonColor: Theme.of(context).colorScheme.primary,
            tooltip: "Create a new list",
          )),
    );
  }
}
