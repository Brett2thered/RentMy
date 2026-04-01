import { View, Text, Pressable } from "react-native";
import { Link } from "expo-router";
import { useAuthStore } from "../../lib/auth";

export default function LoginScreen() {
  const login = useAuthStore((s) => s.login);

  return (
    <View className="flex-1 items-center justify-center bg-white px-6">
      <Text className="text-3xl font-bold mb-2">RentMy</Text>
      <Text className="text-gray-500 mb-8">Rent anything nearby, fast</Text>

      <Pressable
        className="w-full bg-primary-600 py-4 rounded-xl items-center mb-4"
        onPress={() => login("dev-token", { id: "dev", name: "Dev User", email: "dev@rentmy.app" })}
      >
        <Text className="text-white font-semibold text-lg">Sign In (Dev)</Text>
      </Pressable>

      <Link href="/register" asChild>
        <Pressable className="py-2">
          <Text className="text-primary-600 font-medium">Create an account</Text>
        </Pressable>
      </Link>
    </View>
  );
}
