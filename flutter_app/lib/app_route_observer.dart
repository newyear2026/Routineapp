import 'package:flutter/material.dart';

/// Home 등에서 [RouteAware]로 복귀 시 데이터 갱신에 사용
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
