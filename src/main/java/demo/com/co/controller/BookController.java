package demo.com.co.controller;

import demo.com.co.BookDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/books")
public class BookController {

    private final List<BookDTO> bookList = new ArrayList<>();

    @PostMapping
    public ResponseEntity<String> addBook(@RequestBody BookDTO book) {
        if (book.getTitle() == null || book.getTitle().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Title cannot be empty");
        }
        if (book.getAuthor() == null || book.getAuthor().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Author cannot be empty");
        }
        if (book.getPrice() <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Price must be greater than 0");
        }

        bookList.add(book);
        return ResponseEntity.ok("Book added successfully");
    }

    @GetMapping
    public ResponseEntity<List<BookDTO>> getBooks() {
        return ResponseEntity.ok(bookList);
    }

    @GetMapping("/discounted-price")
    public ResponseEntity<String> getDiscountedPrice(
            @RequestParam double price,
            @RequestParam double discount) {

        if (price <= 0 || discount <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Price and discount must be greater than 0");
        }

        double discounted = price - (price * (discount / 100));
        return ResponseEntity.ok("Discounted price: " + discounted);
    }
}
