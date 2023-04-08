import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reportr/app/components/map_switcher.dart';
import 'package:reportr/app/modules/home/components/report_sheet/views/report_sheet_view.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: controller.getLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AlertDialog(
                icon: const Icon(
                  Icons.warning,
                  size: 40,
                ),
                iconColor: Colors.red,
                title: Text(
                  snapshot.error as String,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return MapSwitcher(
            child: Obx(() => GoogleMap(
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: snapshot.data ?? const LatLng(50, 50),
                    zoom: 15,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapType: MapType.hybrid,
                  onMapCreated: (GoogleMapController mapControl) {
                    controller.mapController = mapControl;
                  },
                  markers: controller.markers.toSet(),
                )),
          );
        },
      ),
      bottomSheet: const ReportSheetView(),
      floatingActionButton: Obx(
        () {
          return AnimatedSlide(
            curve: Curves.fastLinearToSlowEaseIn,
            duration: const Duration(seconds: 1, milliseconds: 400),
            offset: controller.showControls.value
                ? Offset.zero
                : const Offset(0, 50),
            child: FloatingActionButton(
              onPressed: () => controller.goToMyLocation(),
              child: const Icon(Icons.navigation),
            ),
          );
        },
      ),
    );
  }
}
