// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../core/data_binder.dart';
import '../../../model/catalog_item.dart';
import '../../../primitives/simple_items.dart';

extension type IconSchemaData.fromMap(JsonMap _json) {
  factory IconSchemaData({required Object? name}) =>
      IconSchemaData.fromMap({'name': name});

  Object? get nameMap => _json['name'];
}

enum AvailableIcons {
  accountCircle(Icons.account_circle),
  add(Icons.add),
  arrowBack(Icons.arrow_back),
  arrowForward(Icons.arrow_forward),
  attachFile(Icons.attach_file),
  calendarToday(Icons.calendar_today),
  call(Icons.call),
  camera(Icons.camera_alt),
  check(Icons.check),
  close(Icons.close),
  delete(Icons.delete),
  download(Icons.download),
  edit(Icons.edit),
  event(Icons.event),
  error(Icons.error),
  fastForward(Icons.fast_forward),
  favorite(Icons.favorite),
  favoriteOff(Icons.favorite_outline),
  folder(Icons.folder),
  help(Icons.help),
  home(Icons.home),
  info(Icons.info_outline),
  locationOn(Icons.location_on),
  lock(Icons.lock_outline),
  lockOpen(Icons.lock_open_outlined),
  mail(Icons.mail_outline),
  menu(Icons.menu),
  moreVert(Icons.more_vert),
  moreHoriz(Icons.more_horiz),
  notificationsOff(Icons.notifications_none),
  notifications(Icons.notifications),
  pause(Icons.pause),
  payment(Icons.payment),
  person(Icons.person),
  phone(Icons.phone),
  photo(Icons.photo),
  play(Icons.play_arrow),
  print(Icons.print),
  refresh(Icons.refresh),
  rewind(Icons.fast_rewind),
  search(Icons.search),
  send(Icons.send),
  settings(Icons.settings),
  share(Icons.share),
  shoppingCart(Icons.shopping_cart),
  skipNext(Icons.skip_next),
  skipPrevious(Icons.skip_previous),
  star(Icons.star),
  starHalf(Icons.star_half_outlined),
  starOff(Icons.star_outline),
  stop(Icons.stop),
  upload(Icons.upload),
  visibility(Icons.visibility),
  visibilityOff(Icons.visibility_off),
  volumeDown(Icons.volume_down),
  volumeMute(Icons.volume_mute),
  volumeOff(Icons.volume_off),
  volumeUp(Icons.volume_up),
  warning(Icons.warning);

  const AvailableIcons(this.iconData);

  final IconData iconData;

  static List<String> get allAvailable =>
      values.map<String>((icon) => icon.name).toList();

  static AvailableIcons? fromName(String name) {
    for (final AvailableIcons iconName in AvailableIcons.values) {
      if (iconName.name == name) {
        return iconName;
      }
    }
    return null;
  }
}

Widget iconBuilder(CatalogItemContext itemContext) {
  final DataBinder binder = itemContext.binder;
  final iconData = IconSchemaData.fromMap(itemContext.data as JsonMap);
  final ValueNotifier<String?> notifier = binder.subscribeToString(
    iconData.nameMap,
  );

  return ValueListenableBuilder<String?>(
    valueListenable: notifier,
    builder: (context, currentValue, child) {
      final String iconName = currentValue ?? '';
      final IconData icon =
          AvailableIcons.fromName(iconName)?.iconData ?? Icons.broken_image;
      return Icon(icon);
    },
  );
}
