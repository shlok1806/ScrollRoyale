import React, { createContext, useContext, useState, ReactNode } from 'react';

interface BrainCustomization {
  hat: string;
  glasses: string;
  expression: string;
  skin: string;
  effect: string;
  accessory: string;
}

interface BrainCustomizationContextType {
  customization: BrainCustomization;
  updateCustomization: (updates: Partial<BrainCustomization>) => void;
}

const BrainCustomizationContext = createContext<BrainCustomizationContextType | undefined>(undefined);

export function BrainCustomizationProvider({ children }: { children: ReactNode }) {
  const [customization, setCustomization] = useState<BrainCustomization>({
    hat: 'crown',
    glasses: 'sunglasses',
    expression: 'happy',
    skin: 'classic',
    effect: 'purple-aura',
    accessory: 'spoon',
  });

  const updateCustomization = (updates: Partial<BrainCustomization>) => {
    setCustomization(prev => ({ ...prev, ...updates }));
  };

  return (
    <BrainCustomizationContext.Provider value={{ customization, updateCustomization }}>
      {children}
    </BrainCustomizationContext.Provider>
  );
}

export function useBrainCustomization() {
  const context = useContext(BrainCustomizationContext);
  if (!context) {
    throw new Error('useBrainCustomization must be used within BrainCustomizationProvider');
  }
  return context;
}
