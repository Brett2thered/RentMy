import { View, Text, Pressable } from "react-native";
import { router } from "expo-router";

export default function RegisterScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white px-6">
      <Text className="text-2xl font-bold mb-2">Create Account</Text>
      <Text className="text-gray-500 mb-8">Join RentMy to start renting</Text>

      <Pressable
        className="w-full bg-primary-600 py-4 rounded-xl items-center mb-4"
        onPress={() => router.back()}
      >
        <Text className="text-white font-semibold text-lg">Sign Up (Coming Soon)</Text>
      </Pressable>
    </View>
  );
}
