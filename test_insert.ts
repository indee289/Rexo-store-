import { createClient } from '@supabase/supabase-js';

// The environment variables are set in the running container, but I need to load them here.
// I can just import from the app's supabaseClient.ts
import { supabase } from './src/lib/supabaseClient';

async function test() {
  const { data, error } = await supabase.from('products').insert({
    id: "prod_12345",
    title: "Test",
    productType: "digital",
    category: "AI Prompts",
    shortDescription: "test",
    fullDescription: "test",
    coverImage: "test",
    galleryImages: [],
    price: 10,
    discountPrice: 5,
    stock: -1,
    tags: [],
    featuresIncluded: [],
    requirements: [],
    status: "active",
    publishDate: new Date().toISOString(),
    isFree: false,
    isPaid: true
  });
  console.log('Error:', error);
  console.log('Data:', data);
}
test();
