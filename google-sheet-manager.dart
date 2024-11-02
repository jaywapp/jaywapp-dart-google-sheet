import 'dart:ffi';

import 'package:be_my_colleague/Service/GoogleHttpClient.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:google_sign_in/google_sign_in.dart';
import 'google-sheet-range.dart';

class GoogleSheetManager {
  GoogleSignInAccount? account;
  String sheetID = '';

  GoogleSheetManager(GoogleSignInAccount? account, String sheetID) {
    account = account;
    sheetID = sheetID;
  }

  Future<List<List<Object?>>?> GetActiveValues(String sheetName) async {
    if (account == null) return List.empty();

    final headers = await account?.authHeaders ?? new Map<String, String>();
    final authenticatedClient = GoogleHttpClient(headers);
    final sheetsApi = sheets.SheetsApi(authenticatedClient);

    try {
      var sheets = sheetsApi.spreadsheets;

      final spreadsheet = await sheetsApi.spreadsheets.get(sheetID);
      final sheet = spreadsheet.sheets!
          .firstWhere((sheet) => sheet.properties!.title == sheetName);

      final int rowCount = sheet.properties!.gridProperties!.rowCount!;
      final int colCount = sheet.properties!.gridProperties!.columnCount!;

      final range = GoogleSheetRange.Create(sheetName, 1, 1, colCount, rowCount);

      var response = await sheets.values.get(sheetID, range.toString());
      var values = response.values;

      return values;
    } catch (e) {
      return List.empty();
    }
  }

  Future<List<List<Object?>>?> GetRows(
      String sheetName, Bool Function(List<Object?>) checker) async {
    List<List<Object?>> result = [];
    var values = await GetActiveValues(sheetName) ?? List.empty();

    for (int i = 0; i < values.length; i++) {
      var row = values[i];

      if (checker(row) == true) {
        result.add(row);
      }
    }

    return result;
  }

  Future<List<List<Object?>>?> GetRowsByCellValue(
      String sheetName, int columnIndex, Object value) async {

    List<List<Object?>> result = [];
    var values = await GetActiveValues(sheetName) ?? List.empty();
    var idx = columnIndex - 1;

    for (int i = 0; i < values.length; i++) {
      var row = values[i];

      if (row.length <= columnIndex && row[idx] == value) {
        result.add(row);
      }
    }

    return result;
  }
}
