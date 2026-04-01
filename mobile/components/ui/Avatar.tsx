import { View, Text, Image } from "react-native";

interface AvatarProps {
  uri?: string | null;
  name: string;
  size?: "sm" | "md" | "lg";
}

const sizeStyles = {
  sm: { container: "w-8 h-8 rounded-full", text: "text-xs font-medium" },
  md: { container: "w-12 h-12 rounded-full", text: "text-base font-semibold" },
  lg: { container: "w-20 h-20 rounded-full", text: "text-2xl font-bold" },
};

function getInitials(name: string): string {
  return name
    .split(" ")
    .map((part) => part[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function Avatar({ uri, name, size = "md" }: AvatarProps) {
  const styles = sizeStyles[size];

  if (uri) {
    return <Image source={{ uri }} className={styles.container} />;
  }

  return (
    <View className={`${styles.container} bg-primary-100 items-center justify-center`}>
      <Text className={`${styles.text} text-primary-700`}>{getInitials(name)}</Text>
    </View>
  );
}
