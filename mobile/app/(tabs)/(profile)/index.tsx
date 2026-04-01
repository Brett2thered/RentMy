import { View, Text, Pressable } from "react-native";
import { useAuthStore } from "../../../lib/auth";

export default function ProfileScreen() {
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);

  return (
    <View className="flex-1 items-center justify-center bg-white px-6">
      <Text className="text-xl font-semibold">{user?.name || "Profile"}</Text>
      <Text className="text-gray-400 mt-1">{user?.email}</Text>

      <Pressable
        className="mt-8 w-full border border-red-500 py-3 rounded-xl items-center"
        onPress={logout}
      >
        <Text className="text-red-500 font-medium">Sign Out</Text>
      </Pressable>
    </View>
  );
}
