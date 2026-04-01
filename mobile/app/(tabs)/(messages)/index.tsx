import { View, Text } from "react-native";

export default function MessagesScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white">
      <Text className="text-xl font-semibold">Messages</Text>
      <Text className="text-gray-400 mt-2">Your conversations</Text>
    </View>
  );
}
