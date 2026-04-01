import { View, Text } from "react-native";

export default function SearchScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white">
      <Text className="text-xl font-semibold">Search</Text>
      <Text className="text-gray-400 mt-2">Find items to rent</Text>
    </View>
  );
}
