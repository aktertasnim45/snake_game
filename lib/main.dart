import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Snake Game',
      home: SnakeGame(),
    );
  }
}

enum SnakeDirection { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with SingleTickerProviderStateMixin {
  static const int gridSize = 20;
  static const int baseSpeedMillis = 200;

  late List<Point<int>> snake;
  late List<Point<int>> _previousSnake; // Crucial for smooth animation
  late Point<int> foodPosition;
  Point<int>? bonusFoodPosition;
  SnakeDirection direction = SnakeDirection.right;
  SnakeDirection nextDirection = SnakeDirection.right;
  bool isPlaying = false;
  int score = 0;

  late AnimationController _animationController;
  Timer? bonusFoodTimer;
  int normalFoodCounter = 0;
  int bonusIntervalIndex = 0;
  final List<int> bonusIntervals = [10, 5, 7, 9, 6];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseSpeedMillis),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        moveSnake();
        if (isPlaying) {
          _animationController.forward(from: 0.0);
        }
      }
    });
    // Set initial state before the game starts
    snake = [const Point(2, 0), const Point(1, 0), const Point(0, 0)];
    _previousSnake = List.from(snake);
    foodPosition = const Point(5, 5);
  }

  void startGame() {
    setState(() {
      snake = [const Point(2, 0), const Point(1, 0), const Point(0, 0)];
      _previousSnake = List.from(snake);
      direction = SnakeDirection.right;
      nextDirection = SnakeDirection.right;
      score = 0;
      normalFoodCounter = 0;
      bonusIntervalIndex = 0;
      bonusFoodPosition = null;
      bonusFoodTimer?.cancel();
      generateFood();
      isPlaying = true;
    });
    _animationController.forward(from: 0.0);
  }
  
  Point<int> _getRandomPoint() {
    return Point(Random().nextInt(gridSize), Random().nextInt(gridSize));
  }

  void generateFood() {
    foodPosition = _getRandomPoint();
    while (snake.contains(foodPosition)) {
      foodPosition = _getRandomPoint();
    }
  }

  void generateBonusFood() {
    bonusFoodPosition = _getRandomPoint();
    while (snake.contains(bonusFoodPosition) || foodPosition == bonusFoodPosition) {
      bonusFoodPosition = _getRandomPoint();
    }
    bonusFoodTimer?.cancel();
    bonusFoodTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => bonusFoodPosition = null);
      }
    });
  }

  void moveSnake() {
    if (!isPlaying) return;

    // IMPORTANT: Store the current snake state before moving
    _previousSnake = List.from(snake);

    setState(() {
      direction = nextDirection;
      Point<int> head = snake.first;
      Point<int> newHead;

      switch (direction) {
        case SnakeDirection.up: newHead = Point(head.x, (head.y - 1 + gridSize) % gridSize); break;
        case SnakeDirection.down: newHead = Point(head.x, (head.y + 1) % gridSize); break;
        case SnakeDirection.left: newHead = Point((head.x - 1 + gridSize) % gridSize, head.y); break;
        case SnakeDirection.right: newHead = Point((head.x + 1) % gridSize, head.y); break;
      }

      if (snake.contains(newHead)) {
        gameOver();
        return;
      }
      
      snake.insert(0, newHead);

      if (newHead == foodPosition) {
        score++;
        normalFoodCounter++;
        if (normalFoodCounter >= bonusIntervals[bonusIntervalIndex]) {
          generateBonusFood();
          normalFoodCounter = 0;
          bonusIntervalIndex = (bonusIntervalIndex + 1) % bonusIntervals.length;
        }
        generateFood();
      } else if (newHead == bonusFoodPosition) {
        score += 5;
        bonusFoodPosition = null;
        bonusFoodTimer?.cancel();
      } else {
        snake.removeLast();
      }
    });
  }

  void gameOver() {
    isPlaying = false;
    _animationController.stop();
    bonusFoodTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); startGame(); }, child: const Text('Play Again')),
        ],
      ),
    );
  }

  double _getRotationAngle(Point<int> from, Point<int> to) {
    Point<int> delta = to - from;
    if (delta == const Point(1, 0)) return pi / 2; // Right
    if (delta == const Point(-1, 0)) return -pi/2; // Left
    if (delta == const Point(0, 1)) return pi; // Down
    if (delta == const Point(0, -1)) return 0 ; // Up
    return 0;
  }

  double _getBendAngle(Point<int> prev, Point<int> current, Point<int> next) {
    Point<int> prevDelta = current - prev;
    Point<int> nextDelta = next - current;

    if ((prevDelta == const Point(0, -1) && nextDelta == const Point(1, 0)) || (prevDelta == const Point(-1, 0) && nextDelta == const Point(0, 1))) {
      return 0; // Coming from UP turning RIGHT, or from LEFT turning DOWN
    } else if ((prevDelta == const Point(1, 0) && nextDelta == const Point(0, 1)) || (prevDelta == const Point(0, -1) && nextDelta == const Point(-1, 0))) {
      return pi / 2; // Coming from RIGHT turning DOWN, or from UP turning LEFT
    } else if ((prevDelta == const Point(0, 1) && nextDelta == const Point(-1, 0)) || (prevDelta == const Point(1, 0) && nextDelta == const Point(0, -1))) {
      return pi; // Coming from DOWN turning LEFT, or from RIGHT turning UP
    } else if ((prevDelta == const Point(-1, 0) && nextDelta == const Point(0, -1)) || (prevDelta == const Point(0, 1) && nextDelta == const Point(1, 0))) {
      return -pi / 2; // Coming from LEFT turning UP, or from DOWN turning RIGHT
    }
    return 0;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (direction != SnakeDirection.down && details.delta.dy < -1) { nextDirection = SnakeDirection.up; } 
                else if (direction != SnakeDirection.up && details.delta.dy > 1) { nextDirection = SnakeDirection.down; }
              },
              onHorizontalDragUpdate: (details) {
                if (direction != SnakeDirection.right && details.delta.dx < -1) { nextDirection = SnakeDirection.left; } 
                else if (direction != SnakeDirection.left && details.delta.dx > 1) { nextDirection = SnakeDirection.right; }
              },
              child: LayoutBuilder(builder: (context, constraints) {
                final double cellSize = constraints.maxWidth / gridSize;
                
                return Stack(
                  children: [
                    // Render all snake parts
                    ...List.generate(snake.length, (index) {
                      final pos = snake[index];
                      // Use _previousSnake for the starting point of the animation
                      final prevPos = _previousSnake.length > index ? _previousSnake[index] : pos;

                      final animationValue = _animationController.value;
                      final top = (prevPos.y * (1 - animationValue) + pos.y * animationValue) * cellSize;
                      final left = (prevPos.x * (1 - animationValue) + pos.x * animationValue) * cellSize;
                      
                      Widget part;
                      double angle = 0;

                      if (index == 0) {
                        part = Image.asset('assets/images/snake_head.png', fit: BoxFit.fill);
                        angle = _getRotationAngle(snake[1], snake[0]);
                      } else if (index == snake.length - 1) {
                        part = Image.asset('assets/images/snake_tail.png', fit: BoxFit.fill);
                        angle = _getRotationAngle(snake[index], snake[index - 1]);
                      } else {
                        Point<int> nextSegment = snake[index - 1];
                        Point<int> prevSegment = snake[index + 1];
                        if ((nextSegment.x == prevSegment.x) || (nextSegment.y == prevSegment.y)) {
                          part = Image.asset('assets/images/snake_body.png', fit: BoxFit.fill);
                          angle = _getRotationAngle(prevSegment, pos);
                        } else {
                          part = Image.asset('assets/images/snake_bend_body.png', fit: BoxFit.fill);
                          angle = _getBendAngle(prevSegment, pos, nextSegment);
                        }
                      }
                      
                      return Positioned(
                        top: top, left: left, width: cellSize, height: cellSize,
                        child: Transform.rotate(angle: angle, child: part),
                      );
                    }),
                    
                    // Render food items
                    if (isPlaying) ...[
                      Positioned(
                        top: foodPosition.y * cellSize, left: foodPosition.x * cellSize,
                        width: cellSize, height: cellSize,
                        child: Image.asset('assets/images/food.png', fit: BoxFit.fill),
                      ),
                      if (bonusFoodPosition != null)
                        Positioned(
                          top: bonusFoodPosition!.y * cellSize, left: bonusFoodPosition!.x * cellSize,
                          width: cellSize, height: cellSize,
                          child: Image.asset('assets/images/bonus_food.png', fit: BoxFit.fill),
                        ),
                    ]
                  ],
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Score: $score', style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          if (!isPlaying) Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(onPressed: startGame, child: const Text('Start Game')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    bonusFoodTimer?.cancel();
    super.dispose();
  }
} 