import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reportr/app/modules/home/report_sheet/controllers/report_sheet_controller.dart';

class HomeController extends GetxController {
  final sheetController = DraggableScrollableController();
  final markers = <Marker>{}.obs;

  final showControls = false.obs;

  late GoogleMapController mapController;
  var scrollController = ScrollController();

  @override
  void onInit() {
    Timer(
      5.seconds,
      () => getLocations(),
    );
    super.onInit();
  }

  Future<LatLng> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Локацията е спряна');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Не сте дали разрешение да се ползва локацията');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Не сте дали разрешение да се ползва локацията');
    }

    showControls.value = true;
    var position = await Geolocator.getCurrentPosition();
    return Future.value(LatLng(position.latitude, position.longitude));
  }

  Future<void> goToMyLocation() async {
    var position = await getLocation();

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15),
      ),
    );
  }

  Future getLocations() async {
    // TODO: Get locations from firebase

// example data
    print("hello world");
    markers.add(
      Marker(
        markerId: const MarkerId("PGEE"),
        position: const LatLng(42.49777, 27.468258),
        onTap: () => Get.find<ReportSheetController>().showReportForm("PGEE"),
      ),
    );
  }

  Future<BitmapDescriptor> convertImageFileToCustomBitmapDescriptor(
    Uint8List imageUint8List, {
    int size = 150,
    bool addBorder = false,
    Color borderColor = Colors.white,
    double borderSize = 10,
    required String title,
    Color titleColor = Colors.white,
    Color titleBackgroundColor = Colors.black,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final double radius = size.toDouble();

    //make canvas clip path to prevent image drawing over the circle
    final Path clipPath = Path();
    clipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        const Radius.circular(100)));
    clipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 3 / 10),
        const Radius.circular(100)));
    canvas.clipPath(clipPath);

    //paintImage
    final ui.Codec codec = await ui.instantiateImageCodec(imageUint8List);
    final ui.FrameInfo imageFI = await codec.getNextFrame();

    paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        image: imageFI.image);

    if (addBorder) {
      //draw Border
      paint
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderSize;
      canvas.drawCircle(Offset(radius, radius), radius, paint);
    }

    if (title.split(" ").length > 1) {
      title = title.split(" ")[0];
    }

    paint
      ..color = titleBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 3 / 10),
            const Radius.circular(100)),
        paint);

    //draw Title
    textPainter.text = TextSpan(
        text: title,
        style: TextStyle(
          fontSize: radius / 2.5,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ));
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(radius - textPainter.width / 2,
            size * 9.5 / 10 - textPainter.height / 2));

    //convert canvas as PNG bytes
    final image = await pictureRecorder
        .endRecording()
        .toImage(size, (size * 1.1).toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    //convert PNG bytes as BitmapDescriptor
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
