import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "8 Queens",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QueensScreen(),
    );
  }
}

class QueensScreen extends StatefulWidget {
  const QueensScreen({super.key});

  @override
  State<QueensScreen> createState() => _QueensScreenState();
}

class _QueensScreenState extends State<QueensScreen> {
  List<List<int>> solutions = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    solutions = solveEightQueens();
  }

  // -----------------------------
  //  Tính toàn bộ 92 lời giải
  // -----------------------------
  List<List<int>> solveEightQueens() {
    const int n = 8;
    List<int> queens = List.filled(n, -1);
    List<List<int>> result = [];

    bool isSafe(int row, int col) {
      for (int i = 0; i < row; i++) {
        int prev = queens[i];
        if (prev == col) return false;
        if ((row - i).abs() == (col - prev).abs()) return false;
      }
      return true;
    }

    void backtrack(int row) {
      if (row == n) {
        result.add(List.from(queens));
        return;
      }
      for (int col = 0; col < n; col++) {
        if (isSafe(row, col)) {
          queens[row] = col;
          backtrack(row + 1);
          queens[row] = -1;
        }
      }
    }

    backtrack(0);
    return result;
  }

  // -----------------------------
  //  Swipe để đổi lời giải
  // -----------------------------
  void nextSolution() {
    setState(() {
      currentIndex = (currentIndex + 1) % solutions.length;
    });
  }

  void previousSolution() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + solutions.length) % solutions.length;
    });
  }

  // -----------------------------
  //  UI bàn cờ
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    List<int> board = solutions[currentIndex];

    return GestureDetector(
      // quệt trái/phải
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          nextSolution(); // quệt trái → next
        } else if (details.primaryVelocity! > 0) {
          previousSolution(); // quệt phải → previous
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text("Lời giải ${currentIndex + 1} / ${solutions.length}"),
          centerTitle: true,
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildChessBoard(board),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: previousSolution,
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: nextSolution,
                    child: const Icon(Icons.arrow_forward),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  //  Vẽ bàn cờ + hậu
  // -----------------------------
  Widget buildChessBoard(List<int> board) {
    const cellSize = 40.0;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black,
      child: Column(
        children: List.generate(8, (row) {
          return Row(
            children: List.generate(8, (col) {
              bool isQueen = board[row] == col;
              bool isLight = (row + col) % 2 == 0;

              return Container(
                width: cellSize,
                height: cellSize,
                color: isLight ? Colors.brown[200] : Colors.brown[600],
                child: isQueen
                    ? const Center(
                  child: Text(
                    "♛",
                    style: TextStyle(
                        fontSize: 28, color: Colors.white),
                  ),
                )
                    : null,
              );
            }),
          );
        }),
      ),
    );
  }
}
