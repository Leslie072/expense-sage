import 'package:currency_picker/currency_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/helpers/color.helper.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/screens/reports/reports_screen.dart';
import 'package:expense_sage/screens/security/security_settings_screen.dart';
import 'package:expense_sage/widgets/buttons/button.dart';
import 'package:expense_sage/widgets/dialog/confirm.modal.dart';
import 'package:expense_sage/widgets/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        body: ListView(
          children: [
            ListTile(
              dense: true,
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      TextEditingController controller = TextEditingController(
                          text: context.read<AppCubit>().state.username);
                      return AlertDialog(
                        title: const Text(
                          "Profile",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What should we call you?",
                              style: theme.textTheme.bodyLarge!.apply(
                                  color: ColorHelper.darken(
                                      theme.textTheme.bodyLarge!.color!),
                                  fontWeightDelta: 1),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                  label: const Text("Name"),
                                  hintText: "Enter your name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 15)),
                            )
                          ],
                        ),
                        actions: [
                          Row(
                            children: [
                              Expanded(
                                  child: AppButton(
                                onPressed: () {
                                  if (controller.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Please enter name")));
                                  } else {
                                    context
                                        .read<AppCubit>()
                                        .updateUsername(controller.text);
                                    Navigator.of(context).pop();
                                  }
                                },
                                height: 45,
                                label: "Save",
                              ))
                            ],
                          )
                        ],
                      );
                    });
              },
              leading: const CircleAvatar(child: Icon(Symbols.person)),
              title: Text('Name',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle:
                  BlocBuilder<AppCubit, AppState>(builder: (context, state) {
                return Text(state.username!,
                    style: Theme.of(context).textTheme.bodySmall?.apply(
                        color: Colors.grey, overflow: TextOverflow.ellipsis));
              }),
            ),
            ListTile(
              dense: true,
              onTap: () {
                showCurrencyPicker(
                    context: context,
                    onSelect: (Currency currency) {
                      context.read<AppCubit>().updateCurrency(currency.code);
                    });
              },
              leading:
                  BlocBuilder<AppCubit, AppState>(builder: (context, state) {
                Currency? currency =
                    CurrencyService().findByCode(state.currency!);
                return CircleAvatar(child: Text(currency!.symbol));
              }),
              title: Text('Currency',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle:
                  BlocBuilder<AppCubit, AppState>(builder: (context, state) {
                Currency? currency =
                    CurrencyService().findByCode(state.currency!);
                return Text(currency!.name,
                    style: Theme.of(context).textTheme.bodySmall?.apply(
                        color: Colors.grey, overflow: TextOverflow.ellipsis));
              }),
            ),
            ListTile(
              dense: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
              leading: const CircleAvatar(child: Icon(Symbols.analytics)),
              title: Text('Reports & Analytics',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle: Text("View spending reports and analytics",
                  style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
            ListTile(
              dense: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
              leading: const CircleAvatar(child: Icon(Symbols.security)),
              title: Text('Security Settings',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle: Text("Manage biometric and two-factor authentication",
                  style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
            ListTile(
              dense: true,
              onTap: () async {
                ConfirmModal.showConfirmDialog(context,
                    title: "Are you sure?",
                    content:
                        const Text("want to export all the data to a file"),
                    onConfirm: () async {
                  Navigator.of(context).pop();
                  LoadingModal.showLoadingDialog(context,
                      content: const Text("Exporting data please wait"));
                  await export().then((value) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("File has been saved in $value")));
                    }
                  }).catchError((err) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Something went wrong while exporting data")));
                    }
                  }).whenComplete(() {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }, onCancel: () {
                  Navigator.of(context).pop();
                });
              },
              leading: const CircleAvatar(
                  child: Icon(
                Symbols.download,
              )),
              title: Text('Export',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle: Text("Export to file",
                  style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
            ListTile(
              dense: true,
              onTap: () async {
                await FilePicker.platform.pickFiles(
                    dialogTitle: "Pick file",
                    allowMultiple: false,
                    allowCompression: false,
                    type: FileType.custom,
                    allowedExtensions: ["json"]).then((pick) {
                  if (pick == null || pick.files.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select file")));
                    }
                    return;
                  }
                  PlatformFile file = pick.files.first;
                  if (mounted) {
                    ConfirmModal.showConfirmDialog(context,
                        title: "Are you sure?",
                        content: const Text(
                            "All payment data, categories, and accounts will be erased and replaced with the information imported from the backup."),
                        onConfirm: () async {
                      Navigator.of(context).pop();
                      LoadingModal.showLoadingDialog(context,
                          content: const Text("Exporting data please wait"));
                      await import(file.path!).then((value) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Successfully imported.")));
                          Navigator.of(context).pop();
                        }
                      }).catchError((err) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Something went wrong while importing data")));
                        }
                      });
                    }, onCancel: () {
                      Navigator.of(context).pop();
                    });
                  }
                }).catchError((err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Something went wrong while importing data")));
                  }
                });
              },
              leading: const CircleAvatar(
                  child: Icon(
                Symbols.upload,
              )),
              title: Text('Import',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle: Text("Import from backup file",
                  style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
            const Divider(),
            ListTile(
              dense: true,
              onTap: () async {
                ConfirmModal.showConfirmDialog(context,
                    title: "Sign Out?",
                    content: const Text("Are you sure you want to sign out?"),
                    onConfirm: () async {
                  Navigator.of(context).pop();
                  context.read<AuthCubit>().logout();
                }, onCancel: () {
                  Navigator.of(context).pop();
                });
              },
              leading: CircleAvatar(
                  backgroundColor: Colors.red.withAlpha(90),
                  child: const Icon(Symbols.logout, color: Colors.red)),
              title: Text('Sign Out',
                  style: Theme.of(context).textTheme.bodyMedium?.merge(
                      const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15))),
              subtitle: Text("Sign out of your account",
                  style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
            // ListTile(
            //   dense: true,
            //   onTap: () async {
            //     ConfirmModal.showConfirmDialog(
            //         context, title: "Are you sure?",
            //         content: const Text("After deleting data can't be recovered"),
            //         onConfirm: ()async{
            //           Navigator.of(context).pop();
            //           Navigator.of(context).pop();
            //           await context.read<AppCubit>().reset();
            //           await resetDatabase();
            //         },
            //         onCancel: (){
            //           Navigator.of(context).pop();
            //         }
            //     );
            //   },
            //   leading: CircleAvatar(
            //       backgroundColor: ThemeColors.error.withAlpha(90),
            //       child: const Icon(Symbols.device_reset,)
            //   ),
            //   title:  Text('Reset', style: Theme.of(context).textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
            //   subtitle:  Text("Delete all the data",style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis)),
            // ),
          ],
        ));
  }
}
