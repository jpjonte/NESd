import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/paginated_grid_controller.dart';

void main() {
  test('starts on the first page', () {
    final controller = PaginatedGridController()..pageCount = 3;

    expect(controller.page, 0);
  });

  test('the next page advances by one', () {
    final controller = PaginatedGridController()
      ..pageCount = 3
      ..nextPage();

    expect(controller.page, 1);
  });

  test('the previous page goes back by one', () {
    final controller = PaginatedGridController()
      ..pageCount = 3
      ..nextPage()
      ..nextPage()
      ..previousPage();

    expect(controller.page, 1);
  });

  test('the next page stops on the last page', () {
    final controller = PaginatedGridController()
      ..pageCount = 2
      ..nextPage()
      ..nextPage();

    expect(controller.page, 1);
  });

  test('the previous page stops on the first page', () {
    final controller = PaginatedGridController()
      ..pageCount = 2
      ..previousPage();

    expect(controller.page, 0);
  });

  test('a shrinking page count pulls the page back into range', () {
    final controller = PaginatedGridController()
      ..pageCount = 3
      ..nextPage()
      ..nextPage()
      ..pageCount = 2;

    expect(controller.page, 1);
  });

  test('only a real page change notifies listeners', () {
    var notifications = 0;

    PaginatedGridController()
      ..pageCount = 2
      ..addListener(() => notifications++)
      ..nextPage()
      // already on the last page
      ..nextPage()
      ..previousPage();

    expect(notifications, 2);
  });
}
