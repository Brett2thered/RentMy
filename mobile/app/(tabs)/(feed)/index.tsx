import { View, Text } from "react-native";

export default function FeedScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white">
      <Text className="text-xl font-semibold">Available Near You</Text>
      <Text className="text-gray-400 mt-2">Listings will appear here</Text>
    </View>
  );
}
