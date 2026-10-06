import '../models/expense_category.dart';
import '../models/parsed_receipt.dart';

class ReceiptParser {
  // Common Vietnamese & International merchants
  static const List<Map<String, dynamic>> _knownMerchants = [
    {'name': 'Highlands Coffee', 'category': ExpenseCategory.food, 'keywords': ['highlands', 'highland coffee']},
    {'name': 'The Coffee House', 'category': ExpenseCategory.food, 'keywords': ['the coffee house', 'coffee house']},
    {'name': 'Phúc Long Coffee & Tea', 'category': ExpenseCategory.food, 'keywords': ['phuc long', 'phúc long']},
    {'name': 'Trung Nguyên Legend', 'category': ExpenseCategory.food, 'keywords': ['trung nguyen', 'trung nguyên']},
    {'name': 'KFC Vietnam', 'category': ExpenseCategory.food, 'keywords': ['kfc']},
    {'name': 'Lotteria', 'category': ExpenseCategory.food, 'keywords': ['lotteria']},
    {'name': 'Jollibee', 'category': ExpenseCategory.food, 'keywords': ['jollibee']},
    {'name': 'Co.op Mart', 'category': ExpenseCategory.shopping, 'keywords': ['co.op mart', 'coopmart', 'coop mart', 'saigon coop']},
    {'name': 'WinMart / WinMart+', 'category': ExpenseCategory.shopping, 'keywords': ['winmart', 'vinmart']},
    {'name': 'Bách Hóa Xanh', 'category': ExpenseCategory.shopping, 'keywords': ['bach hoa xanh', 'bách hóa xanh']},
    {'name': 'Circle K', 'category': ExpenseCategory.shopping, 'keywords': ['circle k']},
    {'name': 'GS25 Convenience', 'category': ExpenseCategory.shopping, 'keywords': ['gs25']},
    {'name': 'FamilyMart', 'category': ExpenseCategory.shopping, 'keywords': ['familymart']},
    {'name': 'Lotte Mart', 'category': ExpenseCategory.shopping, 'keywords': ['lotte mart']},
    {'name': 'Petrolimex', 'category': ExpenseCategory.transport, 'keywords': ['petrolimex', 'xăng dầu', 'petro']},
    {'name': 'Grab', 'category': ExpenseCategory.transport, 'keywords': ['grab', 'grabfood', 'grabbike']},
    {'name': 'Be Group', 'category': ExpenseCategory.transport, 'keywords': ['be bike', 'be car']},
    {'name': 'Nhà Thuốc Long Châu', 'category': ExpenseCategory.health, 'keywords': ['long chau', 'long châu', 'fpt long chau']},
    {'name': 'Pharmacity', 'category': ExpenseCategory.health, 'keywords': ['pharmacity']},
    {'name': 'Nhà Sách Fahasa', 'category': ExpenseCategory.education, 'keywords': ['fahasa']},
    {'name': 'VKU Photocopy & Book', 'category': ExpenseCategory.education, 'keywords': ['vku', 'photocopy', 'in an']},
    {'name': 'CGV Cinemas', 'category': ExpenseCategory.entertainment, 'keywords': ['cgv']},
    {'name': 'Lotte Cinema', 'category': ExpenseCategory.entertainment, 'keywords': ['lotte cinema']},
    {'name': 'Điện Lực EVN', 'category': ExpenseCategory.utilities, 'keywords': ['evn', 'dien luc', 'tiền điện']},
  ];

  /// Main parse method turning raw OCR text into structured ParsedReceipt
  static ParsedReceipt parse(String rawText, {String? imagePath}) {
    final cleaned = rawText.trim();
    if (cleaned.isEmpty) {
      return const ParsedReceipt(
        merchantName: 'Hóa đơn chưa xác định',
        rawText: '',
        confidenceScore: 0.0,
      );
    }

    final total = extractTotal(cleaned);
    final date = extractDate(cleaned);
    final (merchant, matchedCategory) = extractMerchant(cleaned);
    final category = matchedCategory ?? guessCategory(merchant, cleaned);
    final lineItems = extractLineItems(cleaned);

    // Compute heuristic confidence score based on extracted fields
    double confidence = 0.4;
    if (total != null && total > 0) confidence += 0.35;
    if (date != null) confidence += 0.15;
    if (merchant != 'Hóa đơn bán lẻ' && merchant != 'Cửa hàng tiện lợi') confidence += 0.1;
    if (confidence > 0.98) confidence = 0.98;

    return ParsedReceipt(
      merchantName: merchant,
      totalAmount: total,
      date: date ?? DateTime.now(),
      suggestedCategory: category,
      rawText: cleaned,
      confidenceScore: confidence,
      lineItems: lineItems,
      localImagePath: imagePath,
    );
  }

  /// Extracts monetary total based on Slide 42 regex logic + advanced VN heuristics
  static double? extractTotal(String rawText) {
    // Priority 1: Strict Total Keywords
    final highPriorityKeywords = RegExp(
      r'(tổng cộng|tong cong|thanh toán|thanh toan|tổng thanh toán|cần thanh toán|phải trả|phai tra|total|amount due|grand total)',
      caseSensitive: false,
    );

    // Priority 2: Secondary Total Keywords
    final mediumPriorityKeywords = RegExp(
      r'(tổng tiền|tong tien|tiền hàng|tien hang|cộng tiền|cong tien|tiền mặt|tien mat)',
      caseSensitive: false,
    );

    final numberPattern = RegExp(r'[\d]{1,3}(?:[.,]\d{3})*(?:\.\d{2})?');
    final plainNumberPattern = RegExp(r'\b\d{4,9}\b');

    final lines = rawText.split('\n');

    // Pass 1: High priority keywords
    for (final line in lines) {
      if (highPriorityKeywords.hasMatch(line)) {
        final total = _extractNumberFromLine(line, numberPattern, plainNumberPattern);
        if (total != null && total > 0) return total;
      }
    }

    // Pass 2: Medium priority keywords
    for (final line in lines) {
      if (mediumPriorityKeywords.hasMatch(line)) {
        final total = _extractNumberFromLine(line, numberPattern, plainNumberPattern);
        if (total != null && total > 0) return total;
      }
    }

    // Pass 3: Check lines from bottom up for numbers accompanied by "đ", "vnd", "vnđ"
    final currencyPattern = RegExp(r'(\d[\d., ]*)\s*(đ|vnd|vnđ|d)\b', caseSensitive: false);
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final match = currencyPattern.firstMatch(line);
      if (match != null) {
        final rawNum = match.group(1)?.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
        final val = double.tryParse(rawNum ?? '');
        if (val != null && val >= 1000) return val;
      }
    }

    // Pass 4: Fallback to largest reasonable monetary number on the receipt
    double maxCandidate = 0;
    for (final line in lines) {
      final matches = numberPattern.allMatches(line);
      for (final m in matches) {
        final clean = m.group(0)!.replaceAll('.', '').replaceAll(',', '');
        final val = double.tryParse(clean);
        if (val != null && val >= 1000 && val <= 100000000) {
          if (val > maxCandidate) {
            maxCandidate = val;
          }
        }
      }
    }

    return maxCandidate > 0 ? maxCandidate : null;
  }

  static double? _extractNumberFromLine(
    String line,
    RegExp numberPattern,
    RegExp plainNumberPattern,
  ) {
    final matches = numberPattern.allMatches(line);
    if (matches.isNotEmpty) {
      for (final m in matches.toList().reversed) {
        final raw = m.group(0)!.replaceAll('.', '').replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val != null && val >= 1000) return val;
      }
    }

    final plainMatches = plainNumberPattern.allMatches(line);
    if (plainMatches.isNotEmpty) {
      for (final m in plainMatches.toList().reversed) {
        final val = double.tryParse(m.group(0)!);
        if (val != null && val >= 1000) return val;
      }
    }
    return null;
  }

  /// Extracts date from receipt text
  static DateTime? extractDate(String rawText) {
    // Format 1: dd/MM/yyyy or dd-MM-yyyy or dd.MM.yyyy
    final dmyPattern = RegExp(r'\b(0?[1-9]|[12]\d|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b');
    final dmyMatch = dmyPattern.firstMatch(rawText);
    if (dmyMatch != null) {
      try {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // Format 2: yyyy-MM-dd or yyyy/MM/dd
    final ymdPattern = RegExp(r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12]\d|3[01])\b');
    final ymdMatch = ymdPattern.firstMatch(rawText);
    if (ymdMatch != null) {
      try {
        final year = int.parse(ymdMatch.group(1)!);
        final month = int.parse(ymdMatch.group(2)!);
        final day = int.parse(ymdMatch.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // Format 3: dd/MM/yy
    final shortPattern = RegExp(r'\b(0?[1-9]|[12]\d|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](2[3-9])\b');
    final shortMatch = shortPattern.firstMatch(rawText);
    if (shortMatch != null) {
      try {
        final day = int.parse(shortMatch.group(1)!);
        final month = int.parse(shortMatch.group(2)!);
        final year = int.parse('20${shortMatch.group(3)!}');
        return DateTime(year, month, day);
      } catch (_) {}
    }

    return null;
  }

  /// Extracts merchant name and associated category
  static (String merchant, ExpenseCategory? category) extractMerchant(String rawText) {
    final lower = rawText.toLowerCase();

    // 1. Check known brands first
    for (final item in _knownMerchants) {
      final keywords = item['keywords'] as List<String>;
      for (final kw in keywords) {
        if (lower.contains(kw.toLowerCase())) {
          return (item['name'] as String, item['category'] as ExpenseCategory);
        }
      }
    }

    // 2. Scan top 4 lines
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    const ignoredHeaders = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'phiếu tính tiền', 'phieu tinh tien', 'receipt', 'invoice',
      'cộng hòa xã hội chủ nghĩa việt nam', 'vat', 'gtgt', 'ban le'
    ];

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();
      final isIgnored = ignoredHeaders.any((h) => lineLower.contains(h));
      if (!isIgnored && line.length >= 3 && !RegExp(r'^\d+$').hasMatch(line)) {
        return (line, null);
      }
    }

    return ('Hóa đơn bán lẻ', null);
  }

  /// Automatically guess category based on text content
  static ExpenseCategory guessCategory(String merchant, String rawText) {
    final combined = '${merchant.toLowerCase()} ${rawText.toLowerCase()}';

    if (combined.contains('coffee') ||
        combined.contains('cà phê') ||
        combined.contains('cafe') ||
        combined.contains('trà sữa') ||
        combined.contains('ăn uống') ||
        combined.contains('quán') ||
        combined.contains('bún') ||
        combined.contains('phở') ||
        combined.contains('cơm') ||
        combined.contains('bánh mì') ||
        combined.contains('pizza') ||
        combined.contains('food') ||
        combined.contains('restaurant')) {
      return ExpenseCategory.food;
    }

    if (combined.contains('xăng') ||
        combined.contains('petrol') ||
        combined.contains('grab') ||
        combined.contains('be ') ||
        combined.contains('taxi') ||
        combined.contains('gửi xe') ||
        combined.contains('vé xe') ||
        combined.contains('toll')) {
      return ExpenseCategory.transport;
    }

    if (combined.contains('mart') ||
        combined.contains('siêu thị') ||
        combined.contains('bách hóa') ||
        combined.contains('store') ||
        combined.contains('shop') ||
        combined.contains('mua sắm') ||
        combined.contains('tiện lợi') ||
        combined.contains('quần áo')) {
      return ExpenseCategory.shopping;
    }

    if (combined.contains('điện') ||
        combined.contains('nước') ||
        combined.contains('internet') ||
        combined.contains('viettel') ||
        combined.contains('fpt') ||
        combined.contains('vnpt') ||
        combined.contains('rác') ||
        combined.contains('wifi')) {
      return ExpenseCategory.utilities;
    }

    if (combined.contains('phim') ||
        combined.contains('cinema') ||
        combined.contains('cgv') ||
        combined.contains('karaoke') ||
        combined.contains('bida') ||
        combined.contains('game')) {
      return ExpenseCategory.entertainment;
    }

    if (combined.contains('thuốc') ||
        combined.contains('dược') ||
        combined.contains('pharma') ||
        combined.contains('bác sĩ') ||
        combined.contains('khám') ||
        combined.contains('nha khoa')) {
      return ExpenseCategory.health;
    }

    if (combined.contains('sách') ||
        combined.contains('book') ||
        combined.contains('học phí') ||
        combined.contains('vku') ||
        combined.contains('photocopy') ||
        combined.contains('in ấn') ||
        combined.contains('văn phòng phẩm')) {
      return ExpenseCategory.education;
    }

    return ExpenseCategory.other;
  }

  /// Extracts itemized lines when detected
  static List<ReceiptLineItem> extractLineItems(String rawText) {
    final items = <ReceiptLineItem>[];
    final lines = rawText.split('\n');
    final itemPattern = RegExp(r'^(.+?)\s+([\d]{1,3}(?:[.,]\d{3})*)$');

    for (final line in lines) {
      final trimmed = line.trim();
      final match = itemPattern.firstMatch(trimmed);
      if (match != null) {
        final desc = match.group(1)?.trim() ?? '';
        final amountRaw = match.group(2)?.replaceAll('.', '').replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountRaw);
        if (desc.isNotEmpty && amount != null && amount >= 1000) {
          items.add(ReceiptLineItem(description: desc, amount: amount));
        }
      }
    }
    return items;
  }
}
