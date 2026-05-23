import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const WeatherGeminiApp());
}

class WeatherGeminiApp extends StatelessWidget {
  const WeatherGeminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App with Gemini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  bool isLoading = false;

  String temperature = '';
  String condition = '';
  String cityName = '';
  String aiAdvice = '';

  final String weatherApiKey = 'PASTE_YOUR_OPENWEATHER_API_KEY_HERE';
  final String geminiApiKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is disabled.');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> fetchWeatherData() async {
    setState(() {
      isLoading = true;
      aiAdvice = '';
    });

    try {
      Position position = await getCurrentLocation();

      double latitude = position.latitude;
      double longitude = position.longitude;

      final weatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric';

      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          temperature = data['main']['temp'].toString();
          condition = data['weather'][0]['main'];
          cityName = data['name'];
        });

        await getGeminiAdvice();
      } else {
        setState(() {
          aiAdvice = 'Failed to fetch weather data.';
        });
      }
    } catch (e) {
      setState(() {
        aiAdvice = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getGeminiAdvice() async {
    final geminiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey';

    final prompt =
        'Current weather in $cityName is $temperature degree Celsius with $condition condition. Give short weather advice. Tell whether user should go outside or carry umbrella.';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          aiAdvice =
              data['candidates'][0]['content']['parts'][0]['text'].toString();
        });
      } else {
        setState(() {
          aiAdvice = 'Gemini API failed to generate advice.';
        });
      }
    } catch (e) {
      setState(() {
        aiAdvice = 'Gemini Error: $e';
      });
    }
  }

  Widget weatherCard() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.cloud,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              cityName.isEmpty ? 'No Location Selected' : cityName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              temperature.isEmpty ? '-- °C' : '$temperature °C',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              condition.isEmpty ? 'Weather Condition' : condition,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adviceCard() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'AI Weather Assistant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              aiAdvice.isEmpty
                  ? 'Press the button to get AI-based weather advice.'
                  : aiAdvice,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Weather App with Gemini AI'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            weatherCard(),
            adviceCard(),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: fetchWeatherData,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Get Current Weather'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 14,
                      ),
                    ),
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
