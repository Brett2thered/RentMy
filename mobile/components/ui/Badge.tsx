import { View, Text } from "react-native";

interface BadgeProps {
  label: string;
  variant?: "success" | "warning" | "error" | "info";
}

const variantStyles = {
  success: { bg: "bg-green-100", text: "text-green-800" },
  warning: { bg: "bg-yellow-100", text: "text-yellow-800" },
  error: { bg: "bg-red-100", text: "text-red-800" },
  info: { bg: "bg-blue-100", text: "text-blue-800" },
};

export default function Badge({ label, variant = "info" }: BadgeProps) {
  const styles = variantStyles[variant];

  return (
    <View className={`${styles.bg} px-3 py-1 rounded-full`}>
      <Text className={`${styles.text} text-xs font-medium`}>{label}</Text>
    </View>
  );
}
